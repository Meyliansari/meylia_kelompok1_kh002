import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'auth/after_login.dart';

/// Halaman pertama saat aplikasi dibuka: cek apakah user masih login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final user = FirebaseAuth.instance.currentUser;

    // Sudah pernah login → pastikan akunnya masih valid di server
    if (user != null) {
      try {
        await user.reload();
      } on FirebaseAuthException catch (e) {
        // Tidak ada internet → tetap lanjut pakai sesi yang tersimpan
        if (e.code != 'network-request-failed') {
          // Akun dihapus / diblokir / sesi tidak berlaku → logout paksa
          if (!mounted) return;
          await logoutAndGoToLogin(context,
              message: AuthService.errorMessage(e));
          return;
        }
      }
    }

    if (!mounted) return;
    // Belum login → Login. Sudah login → pos pemeriksaan → halaman sesuai role
    await navigateAfterLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_outlined, color: Colors.white, size: 64),
            const SizedBox(height: 12),
            Text(
              'RuangRancang',
              style: AppTheme.heading(28).copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'Rancang Rumah, Wujudkan Hidup',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}