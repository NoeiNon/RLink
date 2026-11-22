import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'auth_layout.dart' show AppLogo, kFieldBorder, kErrorColor;

const _kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF2A2250), Color(0xFF5865F2)],
);

/// Login/register: latar gradient layar penuh + kartu kecil di tengah.
/// Kartu berisi panel WELCOME (kiri, hanya di layar lebar) dan form (kanan).
class AuthSplitLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? footer;

  const AuthSplitLayout({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Latar penuh = versi besar dari panel di dalam kartu.
          const Positioned.fill(child: _WelcomeContent(big: true)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: LayoutBuilder(
                  builder: (context, _) {
                    final w = MediaQuery.of(context).size.width;
                    final wide = w >= 720;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 720 : 380),
                      child: _Card(
                        wide: wide,
                        title: title,
                        subtitle: subtitle,
                        footer: footer,
                        children: children,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          if (canPop)
            const SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: BackButton(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool wide;
  final String title;
  final String? subtitle;
  final Widget? footer;
  final List<Widget> children;
  const _Card({
    required this.wide,
    required this.title,
    required this.children,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final form = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo di dalam kartu: hanya untuk aplikasi Android/iOS
          // (di web, panel WELCOME sudah menampilkan logo).
          if (!wide && !kIsWeb) ...[
            const Center(child: AppLogo(width: 64)),
            const SizedBox(height: 16),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ColoredBox(
          color: AppColors.background,
          child: wide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
                        flex: 5,
                        child: _WelcomeContent(big: false),
                      ),
                      Expanded(flex: 5, child: Center(child: form)),
                    ],
                  ),
                )
              : form,
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  final bool big;
  const _WelcomeContent({required this.big});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: big ? 0 : 400),
      decoration: const BoxDecoration(gradient: _kBrandGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(width: big ? 72 : 56),
            SizedBox(height: big ? 20 : 14),
            Text(
              'WELCOME',
              style: TextStyle(
                fontSize: big ? 34 : 24,
                fontWeight: FontWeight.w800,
                letterSpacing: big ? 4 : 3,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Field kecil bergaya underline.
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
