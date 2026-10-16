import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/pengguna.dart';

/// Urusan profil akun yang sedang login (user maupun arsitek).
class ProfilService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Data akun saya, update otomatis (live)
  static Stream<Pengguna?> streamSaya() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db
        .collection(Koleksi.users)
        .doc(uid)
        .snapshots()
        .map((d) => d.exists ? Pengguna.fromDoc(d) : null);
  }

  /// Ubah nama di `users` (+ di profil `arsitek` kalau ada)
  static Future<void> ubahNama(String namaBaru) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection(Koleksi.users).doc(user.uid).update({
      'nama': namaBaru,
      'diperbaruiPada': FieldValue.serverTimestamp(),
    });
    await user.updateDisplayName(namaBaru);

    // Arsitek: samakan nama di profil publiknya.
    // Kalau gagal (misal sudah bukan arsitek), abaikan saja.
    try {
      final arsitekRef = _db.collection(Koleksi.arsitek).doc(user.uid);
      if ((await arsitekRef.get()).exists) {
        await arsitekRef.update({'nama': namaBaru});
      }
    } catch (_) {}
  }

  /// Ubah password: wajib cocokkan password lama dulu (re-authentication)
  static Future<void> ubahPassword(String lama, String baru) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw FirebaseAuthException(code: 'no-email');
    }
    final cred = EmailAuthProvider.credential(email: email, password: lama);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(baru);
  }
}