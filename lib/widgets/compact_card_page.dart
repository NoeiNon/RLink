import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'auth_layout.dart' show kFieldBorder;

/// Isi halaman berupa satu kartu kecil di tengah (gaya login/register).
/// Dipakai form pendek seperti Buat server dan Gabung server.
class CompactCardPage extends StatelessWidget {
  const CompactCardPage({
    super.key,
    required this.children,
    this.maxWidth = 380,
  });

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kFieldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
