import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kumpulan warna RuangRancang (sesuai desain: krem + hijau tua)
class AppColors {
  static const background = Color(0xFFF4EFE6); // krem latar
  static const surface = Color(0xFFFBF8F2);    // krem terang (kolom input/kartu)
  static const primary = Color(0xFF2F4A3F);    // hijau tua
  static const textDark = Color(0xFF2B2A27);
  static const textMuted = Color(0xFF8A8376);  // abu kecoklatan
  static const border = Color(0xFFE3DCCF);
}

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.poppins().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.surface,
      ),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Font serif untuk judul (seperti "Selamat datang" di desain)
  static TextStyle heading(double size) => GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  /// Bayangan halus untuk teks putih di atas foto
  static const List<Shadow> textShadow = [
    Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2)),
  ];
}