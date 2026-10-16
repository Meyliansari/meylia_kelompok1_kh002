import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Data dari form Daftar, dibawa ke halaman OTP
class RegistrationData {
  final String name;
  final String email;
  final String phone; // tanpa +62, contoh: 81234567890
  final String password;

  const RegistrationData({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
}

/// Semua urusan login/daftar dengan Firebase ada di sini.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int? _resendToken;

  User? get currentUser => _auth.currentUser;

  // ===================== OTP NOMOR HP =====================

  /// Minta Firebase mengirim kode OTP.
  /// Hasilnya "verificationId" yang nanti dipakai untuk mengecek kode.
  Future<String> sendOtp(String phoneNumber) async {
    final completer = Completer<String>();
    await _auth.setLanguageCode('id');
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      codeSent: (verificationId, resendToken) {
        _resendToken = resendToken;
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
    return completer.future;
  }

  /// DAFTAR (dipanggil setelah kode OTP diketik):
  /// 1. Cek kode OTP → masuk dengan nomor HP
  /// 2. Tempelkan email + password ke akun yang sama
  /// 3. Simpan profil ke Firestore
  /// 4. Kirim email verifikasi
  Future<void> registerWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    required RegistrationData data,
  }) async {
    final phoneCred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(phoneCred);
    final user = result.user!;

    // Nomor ini sudah punya akun → jangan daftar dobel
    if (result.additionalUserInfo?.isNewUser != true) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'phone-already-registered');
    }

    try {
      await user.linkWithCredential(
        EmailAuthProvider.credential(
          email: data.email,
          password: data.password,
        ),
      );
    } catch (e) {
      // Gagal (misal email sudah dipakai) → batalkan akun setengah jadi
      await user.delete();
      rethrow;
    }

    await user.updateDisplayName(data.name);
    await _db.collection('users').doc(user.uid).set({
      'nama': data.name,
      'email': data.email,
      'noHp': data.phone,
      'role': 'user', // admin & arsitek diangkat manual / oleh admin
      'phoneVerified': true,
      'emailVerified': false,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _auth.setLanguageCode('id');
    await user.sendEmailVerification();
  }

  /// MASUK dengan nomor HP (setelah kode OTP diketik)
  Future<void> loginWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(cred);

    // Nomor belum pernah daftar → hapus akun kosong yang barusan tercipta
    if (result.additionalUserInfo?.isNewUser == true) {
      await result.user?.delete();
      throw FirebaseAuthException(code: 'phone-not-registered');
    }
  }

  // ===================== EMAIL =====================

  /// Login dengan email & password
  Future<User> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!;
  }

  /// Muat ulang data user dari server, lalu cek apakah email sudah diverifikasi
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    final verified = user?.emailVerified ?? false;

    if (verified && user != null) {
      // 1. Perbarui "tiket login" supaya Security Rules tahu email sudah terverifikasi
      await user.getIdToken(true);

      // 2. Catat di Firestore. Kalau gagal, jangan menghalangi user masuk,
      //    karena status verifikasi yang asli sudah tersimpan di Firebase Auth.
      try {
        await _db
            .collection('users')
            .doc(user.uid)
            .set({'emailVerified': true}, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Gagal mencatat emailVerified di Firestore: $e');
      }
    }
    return verified;
  }

  Future<void> resendEmailVerification() async {
    await _auth.setLanguageCode('id');
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.setLanguageCode('id');
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ===================== UMUM =====================

  /// Ambil profil user yang sedang login dari Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> logout() => _auth.signOut();

  /// Ubah kode error Firebase jadi pesan yang mudah dipahami user
  static String errorMessage(Object e) {
    // Error dari Authentication (login/daftar/OTP)
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan masuk.';
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'weak-password':
          return 'Password terlalu lemah.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'user-disabled':
          return 'Akun Anda dinonaktifkan. Hubungi admin.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'operation-not-allowed':
          return 'Metode login ini belum diaktifkan di Firebase.';
        case 'invalid-verification-code':
          return 'Kode OTP salah.';
        case 'session-expired':
          return 'Kode OTP kedaluwarsa. Kirim ulang kode.';
        case 'invalid-phone-number':
          return 'Nomor HP tidak valid.';
        case 'credential-already-in-use':
          return 'Nomor HP sudah dipakai akun lain.';
        case 'quota-exceeded':
          return 'Batas pengiriman SMS tercapai. Coba lagi nanti.';
        case 'app-not-authorized':
        case 'missing-client-identifier':
          return 'Aplikasi belum diizinkan. Cek SHA-1 di Firebase.';
        case 'phone-already-registered':
          return 'Nomor HP sudah terdaftar. Silakan masuk.';
        case 'phone-not-registered':
          return 'Nomor HP belum terdaftar. Silakan daftar dulu.';
        default:
          return 'Terjadi kesalahan (${e.code}): ${e.message}';
      }
    }

    // Error dari Firestore / Firebase lainnya
    if (e is FirebaseException) {
      return 'Terjadi kesalahan (${e.plugin}/${e.code}): ${e.message}';
    }

    // Error lain di luar Firebase
    return 'Terjadi kesalahan: $e';
  }
}