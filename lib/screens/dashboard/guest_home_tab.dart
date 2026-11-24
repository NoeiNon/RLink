import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../guest_gate.dart';

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
              'Selamat datang di RLink',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cari kerja, temukan freelance, jualan, atau bangun timmu '
              'sendiri.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: () => openLoginFromGuest(context),
                  child: const Text('Masuk'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => openRegisterFromGuest(context),
                  child: const Text('Daftar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Jelajahi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _ExploreCard(
              icon: Icons.work_outline_rounded,
              title: 'Lowongan',
              text: 'Lihat company yang sedang merekrut.',
              onTap: () => onOpenTab(1),
            ),
            _ExploreCard(
              icon: Icons.business_rounded,
              title: 'Perusahaan & Tim',
              text: 'Kenali company dan tim yang ada.',
              onTap: () => onOpenTab(2),
            ),
            _ExploreCard(
              icon: Icons.handshake_outlined,
              title: 'Freelance',
              text: 'Cari atau tawarkan jasa tanpa harus masuk company.',
              onTap: () => onOpenTab(3),
            ),
            _ExploreCard(
              icon: Icons.storefront_rounded,
              title: 'Store',
              text: 'Jual barangmu atau cari dari penjual lain.',
              onTap: () => onOpenTab(4),
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
      padding: const EdgeInsets.only(bottom: 8),
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
