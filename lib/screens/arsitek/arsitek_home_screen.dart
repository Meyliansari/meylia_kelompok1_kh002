import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../auth/after_login.dart';

/// Beranda Arsitek (sementara): nanti berisi jadwal & konsultasi yang
/// ditugaskan, plus notifikasi tugas baru.
class ArsitekHomeScreen extends StatelessWidget {
  const ArsitekHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda Arsitek'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => logoutAndGoToLogin(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.architecture_outlined,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Halo, Arsitek', style: AppTheme.heading(22)),
              const SizedBox(height: 8),
              const Text(
                'Daftar konsultasi yang ditugaskan akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}