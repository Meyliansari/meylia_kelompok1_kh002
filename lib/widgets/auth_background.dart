import 'package:flutter/material.dart';

/// Latar halaman Login & Daftar: foto rumah yang memudar ke krem.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  // ===== PENGATURAN (ubah angka di sini sesuai selera) =====

  /// Tinggi foto dibanding tinggi layar. 0.5 = setengah layar.
  static const double imageHeightRatio = 0.5;

  /// Kejelasan foto. 0.0 = tidak terlihat, 1.0 = jelas penuh.
  static const double imageOpacity = 0.85;

  /// Titik mulai memudar (0.0 = atas foto, 1.0 = bawah foto).
  static const double fadeStart = 0.6;

  /// Kegelapan bayangan di atas foto (biar teks putih terbaca).
  /// 0.0 = tanpa bayangan, 0.6 = cukup gelap.
  static const double shadeOpacity = 0.5;

  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final photoHeight = screenHeight * imageHeightRatio;

    return Stack(
      children: [
        // Lapisan 1: foto rumah yang memudar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.black, Colors.transparent],
              stops: [0.0, fadeStart, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Image.asset(
              'lib/images/houselogin.jpg',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(imageOpacity),
            ),
          ),
        ),

        // Lapisan 2: bayangan gelap di bagian atas
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: photoHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: shadeOpacity),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.9],
              ),
            ),
          ),
        ),

        // Lapisan 3: isi halaman
        SafeArea(child: child),
      ],
    );
  }
}