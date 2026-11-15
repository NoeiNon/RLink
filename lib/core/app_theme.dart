import 'package:flutter/material.dart';

/// Warna utama aplikasi (nuansa gelap seperti Discord + aksen oranye konstruksi).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF14111C);
  static const Color surface = Color(0xFF1E1A2B);
  static const Color primary = Color(0xFF5865F2);
  static const Color accent = Color(0xFFB69CFF);
  static const Color textPrimary = Color(0xFFF2F0F7);
  static const Color textMuted = Color(0xFF9A96AB);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ).copyWith(surface: AppColors.surface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}
