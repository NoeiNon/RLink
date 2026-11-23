import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'auth_layout.dart' show kFieldBorder;

/// Route untuk popup: halaman di belakangnya tetap terlihat (diburamkan).
/// Dipakai untuk Buat server dan Gabung server.
Route<T> blurDialogRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, _, __) => builder(context),
    transitionsBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Popup berupa satu kartu kecil di tengah, latar belakang diburamkan.
/// Ketuk di luar kartu atau tombol X untuk menutup.
class CompactCardPage extends StatelessWidget {
  const CompactCardPage({
    super.key,
    required this.title,
    required this.children,
    this.maxWidth = 380,
  });

  final String title;
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: ColoredBox(
          color: const Color(0x66000000),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  // Ketukan di dalam kartu tidak menutup popup.
                  child: GestureDetector(
                    onTap: () {},
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: kFieldBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tutup',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
