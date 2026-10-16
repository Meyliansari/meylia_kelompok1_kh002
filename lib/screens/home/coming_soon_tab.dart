import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Halaman sementara untuk tab yang belum dibangun teman sekelompok.
class ComingSoonTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonTab({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(title, style: AppTheme.heading(22)),
              const SizedBox(height: 8),
              const Text(
                'Fitur ini sedang dibangun.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}