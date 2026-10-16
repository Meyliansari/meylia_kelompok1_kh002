import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../admin/admin_home_screen.dart';
import '../../consultation_module/screens/architect_home_screen.dart';
import '../home/home_screen.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

/// Pindah ke halaman baru dan hapus semua halaman sebelumnya,
/// supaya tombol Back tidak bisa kembali ke Login / Splash.
void _goTo(BuildContext context, Widget page) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
        (route) => false,
  );
}

/// Logout lalu kembali ke halaman Login. Dipakai di SEMUA tombol Keluar.
Future<void> logoutAndGoToLogin(BuildContext context, {String? message}) async {
  await AuthService().logout();
  if (!context.mounted) return;
  if (message != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
  _goTo(context, const LoginScreen());
}

/// POS PEMERIKSAAN: dipanggil setelah login (email / No. HP) dan saat
/// aplikasi dibuka (Splash). Cek profil, status, email, lalu buka
/// halaman sesuai role.
Future<void> navigateAfterLogin(BuildContext context) async {
  final authService = AuthService();
  final user = authService.currentUser;

  if (user == null) {
    _goTo(context, const LoginScreen());
    return;
  }

  Map<String, dynamic>? profile;
  try {
    profile = await authService.getUserProfile();
  } catch (e) {
    if (!context.mounted) return;
    await logoutAndGoToLogin(context, message: AuthService.errorMessage(e));
    return;
  }
  if (!context.mounted) return;

  // 1. Profil tidak ada di Firestore
  if (profile == null) {
    await logoutAndGoToLogin(context,
        message: 'Data akun tidak ditemukan. Silakan daftar ulang.');
    return;
  }

  // 2. Akun dinonaktifkan admin
  if (profile['isActive'] == false) {
    await logoutAndGoToLogin(context,
        message: 'Akun Anda dinonaktifkan. Hubungi admin.');
    return;
  }

  // 3. Email belum diverifikasi (berlaku untuk semua role)
  if (!user.emailVerified) {
    _goTo(context, const EmailVerificationScreen());
    return;
  }

  // 4. Buka "rumah" sesuai role
  final role = profile['role'] as String? ?? 'user';
  final Widget home = switch (role) {
    'admin' => const AdminHomeScreen(),
    'arsitek' => const ConsultationArchitectHomeScreen(),
    _ => const HomeScreen(),
  };
  _goTo(context, home);
}