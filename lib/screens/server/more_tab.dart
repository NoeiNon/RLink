import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../models/server.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/page_body.dart';
import 'placeholder_tab.dart';

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

/// Tab "Lainnya": menu yang tidak masuk navigasi bawah digabung di sini,
/// ditambah aksi akun (keluar dari server, keluar akun).
class MoreTab extends StatelessWidget {
  const MoreTab({
    super.key,
    required this.role,
    required this.onLeaveServer,
    required this.onLogout,
  });

  final ServerRole role;
  final VoidCallback onLeaveServer;
  final VoidCallback onLogout;

  bool get _isAdmin => role == ServerRole.admin;

  List<_MenuItem> get _items => [
        _MenuItem(
          icon: Icons.notifications_outlined,
          title: 'Inactive Notice',
          description: _isAdmin
              ? 'Setujui atau tolak pengajuan libur dari builder. '
                  'Builder yang libur tidak bisa claim project dan tidak digaji.'
              : 'Ajukan libur kalau sedang sibuk. Kalau disetujui admin, '
                  'statusmu jadi libur.',
        ),
        const _MenuItem(
          icon: Icons.campaign_outlined,
          title: 'Pengumuman',
          description: 'Pengumuman dari admin untuk semua anggota server.',
        ),
        const _MenuItem(
          icon: Icons.gavel_outlined,
          title: 'SOP',
          description: 'Aturan dan prosedur kerja di server ini.',
        ),
        const _MenuItem(
          icon: Icons.account_tree_outlined,
          title: 'Structure',
          description: 'Struktur dan susunan tim di server ini.',
        ),
        const _MenuItem(
          icon: Icons.forum_outlined,
          title: 'Discussion',
          description: 'Ruang diskusi antar anggota server.',
        ),
      ];

  void _openItem(BuildContext context, _MenuItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
            title: Text(item.title),
          ),
          body: PlaceholderTab(
            icon: item.icon,
            title: item.title,
            description: item.description,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 600,
      children: [
        const _SectionLabel('Menu'),
        for (final item in _items)
          _MenuTile(
            icon: item.icon,
            title: item.title,
            onTap: () => _openItem(context, item),
          ),
        const SizedBox(height: 12),
        const _SectionLabel('Akun'),
        _MenuTile(
          icon: Icons.swap_horiz_rounded,
          title: 'Keluar dari server',
          onTap: onLeaveServer,
        ),
        _MenuTile(
          icon: Icons.logout_rounded,
          title: 'Keluar akun',
          danger: true,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? kErrorColor : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kFieldBorder),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!danger)
                  const Icon(
                    Icons.chevron_right_rounded,
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
