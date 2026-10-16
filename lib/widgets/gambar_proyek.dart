import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Menampilkan gambar proyek dari aset ATAU dari link internet.
/// Kalau gagal dimuat, tampil kotak dengan ikon cadangan (tidak error).
class GambarProyek extends StatelessWidget {
  final String sumber;
  final double? width;
  final double? height;
  final int cacheWidth;

  const GambarProyek(
      this.sumber, {
        super.key,
        this.width,
        this.height,
        this.cacheWidth = 600,
      });

  @override
  Widget build(BuildContext context) {
    final cadangan = Container(
      width: width,
      height: height,
      color: AppColors.border,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined,
          color: AppColors.textMuted),
    );

    if (sumber.isEmpty) return cadangan;

    // Gambar dari internet
    if (sumber.startsWith('http')) {
      return Image.network(
        sumber,
        width: width,
        height: height,
        fit: BoxFit.cover,
        cacheWidth: cacheWidth,
        errorBuilder: (_, __, ___) => cadangan,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
          width: width,
          height: height,
          color: AppColors.surface,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Gambar dari folder lib/images
    return Image.asset(
      sumber,
      width: width,
      height: height,
      fit: BoxFit.cover,
      cacheWidth: cacheWidth,
      errorBuilder: (_, __, ___) => cadangan,
    );
  }
}