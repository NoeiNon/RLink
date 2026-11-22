import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'auth_layout.dart' show AppLogo, kFieldBorder, kErrorColor;

/// Layout login/register ringkas: panel gambar di kiri (layar lebar),
/// form kecil (maks 340px) di kanan. Di layar sempit hanya form.
class AuthSplitLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer; // mis. "Belum punya akun? Daftar"

  const AuthSplitLayout({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 800;
          final form = _FormPanel(
            title: title,
            subtitle: subtitle,
            footer: footer,
            children: children,
          );
          if (!wide) return form;
          return Row(
            children: [
              const Expanded(flex: 5, child: _WelcomePanel()),
              Expanded(flex: 4, child: form),
            ],
          );
        },
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2250), Color(0xFF5865F2)],
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(width: 72),
            SizedBox(height: 20),
            Text(
              'WELCOME',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? footer;
  final List<Widget> children;
  const _FormPanel({
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return SafeArea(
      child: Stack(
        children: [
          if (canPop) const Positioned(top: 4, left: 4, child: BackButton()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ...children,
                    if (footer != null) ...[
                      const SizedBox(height: 16),
                      Center(child: footer!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Field kecil bergaya underline (seperti referensi).
InputDecoration compactInputDecoration({
  required String label,
  String? helper,
  IconData? icon,
  Widget? suffix,
}) {
  const line = UnderlineInputBorder(
    borderSide: BorderSide(color: kFieldBorder),
  );
  return InputDecoration(
    labelText: label,
    helperText: helper,
    helperStyle: const TextStyle(fontSize: 11),
    labelStyle: const TextStyle(fontSize: 13),
    isDense: true,
    prefixIcon: icon == null ? null : Icon(icon, size: 16),
    prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    suffixIcon: suffix,
    suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    contentPadding: const EdgeInsets.symmetric(vertical: 10),
    enabledBorder: line,
    border: line,
    focusedBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: kErrorColor),
    ),
    focusedErrorBorder: const UnderlineInputBorder(
      borderSide: BorderSide(color: kErrorColor, width: 1.5),
    ),
    errorStyle: const TextStyle(fontSize: 11),
  );
}

/// Tombol penuh lebar, tinggi 40.
class CompactButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  const CompactButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}
