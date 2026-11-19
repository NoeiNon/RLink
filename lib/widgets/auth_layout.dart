import 'package:flutter/material.dart';

import '../core/app_theme.dart';

const Color kFieldBorder = Color(0xFF2E2942);
const Color kErrorColor = Color(0xFFED4245);

/// Logo aplikasi (assets/images/logo.png). Kalau file tidak ditemukan,
/// tampil ikon sementara supaya app tetap jalan.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.width = 120});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: width,
      cacheWidth: (width * 3).round(),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.construction_rounded,
        size: width * 0.4,
        color: AppColors.accent,
      ),
    );
  }
}

/// Kerangka halaman form (login, daftar): logo, judul, lalu isi form di tengah
/// dengan lebar maksimal 420. Tombol kembali muncul otomatis kalau halaman ini
/// dibuka dari halaman lain.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.logoWidth = 96,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final double logoWidth;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              scrolledUnderElevation: 0,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: AppLogo(width: logoWidth)),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gaya seragam untuk semua kolom isian.
InputDecoration appInputDecoration({
  required String label,
  String? helper,
  IconData? icon,
  Widget? suffix,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperMaxLines: 2,
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppColors.surface,
    border: border(kFieldBorder),
    enabledBorder: border(kFieldBorder),
    focusedBorder: border(AppColors.primary, 2),
    errorBorder: border(kErrorColor),
    focusedErrorBorder: border(kErrorColor, 2),
  );
}

/// Tombol utama dengan indikator loading. Saat loading, tombol dinonaktifkan.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}
