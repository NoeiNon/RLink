import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show AppLogo, kFieldBorder;
import '../auth/guest_gate.dart' show GuestAuthButtons;

/// Satu tab navigasi di dashboard.
class DashboardTab {
  const DashboardTab(this.label, this.shortLabel, this.icon);

  final String label;
  final String shortLabel; // untuk navigasi bawah di HP
  final IconData icon;
}

/// Indeks tab Pesan. Di HP tab ini tidak masuk navigasi bawah (ikon chat di
/// bar atas yang membukanya), supaya navigasi bawah tidak sesak.
const int kMessagesTabIndex = 1;

const List<DashboardTab> kDashboardTabs = [
  DashboardTab('Beranda', 'Beranda', Icons.home_rounded),
  DashboardTab('Pesan', 'Pesan', Icons.chat_bubble_outline_rounded),
  DashboardTab('Lowongan', 'Lowongan', Icons.work_outline_rounded),
  DashboardTab('Perusahaan & Tim', 'Tim', Icons.business_rounded),
  DashboardTab('Freelance', 'Freelance', Icons.handshake_outlined),
  DashboardTab('Store', 'Store', Icons.storefront_rounded),
  DashboardTab('Server', 'Server', Icons.dns_rounded),
];

/// Sidebar kiri: logo di atas, tab navigasi, dan profil di pojok bawah.
class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.username,
    required this.onProfile,
    required this.onLogout,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final String username;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: kFieldBorder)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const AppLogo(width: 64),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (var i = 0; i < kDashboardTabs.length; i++)
                    _SidebarItem(
                      tab: kDashboardTabs[i],
                      selected: i == index,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: kFieldBorder),
            if (username.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: GuestAuthButtons(),
              )
            else
              _ProfileCard(
                username: username,
                onProfile: onProfile,
                onLogout: onLogout,
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final DashboardTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.textPrimary : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? const Color(0x335865F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 19,
                  color: selected ? AppColors.accent : color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.username,
    required this.onProfile,
    required this.onLogout,
  });

  final String username;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onProfile,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Lihat profil',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Keluar akun',
            iconSize: 19,
            color: AppColors.textMuted,
            icon: const Icon(Icons.logout_rounded),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
