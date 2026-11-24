import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'page_body.dart';

/// Isi sementara untuk tab yang belum dikerjakan. Menjelaskan apa yang
/// nanti ada di tab itu, sesuai peran (admin atau builder).
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 480,
      center: true,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0x335865F2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Segera hadir',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }
}
