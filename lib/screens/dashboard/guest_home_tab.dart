import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;

/// Beranda untuk pengunjung yang belum login: perkenalan singkat dan pintu
/// ke bagian-bagian yang bisa dijelajahi.
class GuestHomeTab extends StatelessWidget {
  const GuestHomeTab({super.key, required this.onOpenTab});

  /// Pindah ke tab lain di dashboard (indeks sesuai `kDashboardTabs`).
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'RLink',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Karier, freelance, dan bisnis dalam satu platform.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, box) {
                final twoCols = box.maxWidth >= 560;
                final cardWidth = twoCols
                    ? (box.maxWidth - 12) / 2
                    : box.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in [
                      (
                        Icons.work_outline_rounded,
                        'Lowongan',
                        'Lihat company yang sedang merekrut.',
                        1,
                      ),
                      (
                        Icons.business_rounded,
                        'Perusahaan & Tim',
                        'Kenali company dan tim yang ada.',
                        2,
                      ),
                      (
                        Icons.handshake_outlined,
                        'Freelance',
                        'Cari atau tawarkan jasa tanpa harus masuk company.',
                        3,
                      ),
                      (
                        Icons.storefront_rounded,
                        'Store',
                        'Jual barangmu atau cari dari penjual lain.',
                        4,
                      ),
                    ])
                      SizedBox(
                        width: cardWidth,
                        child: _ExploreCard(
                          icon: c.$1,
                          title: c.$2,
                          text: c.$3,
                          onTap: () => onOpenTab(c.$4),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kFieldBorder),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
