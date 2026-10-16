import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_background.dart';
import 'after_login.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  bool _checking = false;
  bool _resending = false;

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _onCheckPressed() async {
    setState(() => _checking = true);
    try {
      final verified = await _authService.checkEmailVerified();
      if (!mounted) return;
      if (verified) {
        // Lewat pos pemeriksaan → user/arsitek/admin ke halaman masing-masing
        await navigateAfterLogin(context);
      } else {
        _showMessage(
            'Email belum terverifikasi. Cek inbox atau folder spam ya.');
      }
    } catch (e) {
      _showMessage(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _onResendPressed() async {
    setState(() => _resending = true);
    try {
      await _authService.resendEmailVerification();
      _showMessage('Email verifikasi sudah dikirim ulang.');
    } catch (e) {
      _showMessage(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? '';

    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mark_email_unread_outlined,
                  color: Colors.white, size: 44),
              const SizedBox(height: 16),
              Text(
                'Cek Email\nKamu',
                style: AppTheme.heading(28).copyWith(
                  color: Colors.white,
                  shadows: AppTheme.textShadow,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kami sudah mengirim link verifikasi ke $email. '
                    'Buka email tersebut dan klik link-nya.',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: AppTheme.textShadow,
                ),
              ),
              const SizedBox(height: 120),
              ElevatedButton(
                onPressed: _checking ? null : _onCheckPressed,
                child: _checking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Saya Sudah Verifikasi'),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _resending ? null : _onResendPressed,
                  child: const Text('Kirim ulang email',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => logoutAndGoToLogin(context),
                  child: const Text('Ganti akun',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}