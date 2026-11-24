import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../server/data/mock_server_store.dart';
import '../server/models/server.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../../widgets/compact_card_page.dart' show blurDialogRoute;
import '../server/widgets/server_avatar.dart';
import '../server/screens/create_server_screen.dart';
import '../server/screens/join_server_screen.dart';
import '../server/screens/server_home_screen.dart';

/// Memuat daftar server milik akun dan memuat ulang setelah pengguna
/// kembali dari halaman lain (buat, gabung, atau buka server).
class _ServersLoader extends StatefulWidget {
  const _ServersLoader({required this.username, required this.builder});

  final String username;
  final Widget Function(
    BuildContext context,
    List<ServerMembership>? memberships,
    Future<void> Function(Route<void> route) open,
  )
  builder;

  @override
  State<_ServersLoader> createState() => _ServersLoaderState();
}

class _ServersLoaderState extends State<_ServersLoader> {
  List<ServerMembership>? _memberships;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await MockServerStore.getMemberships(widget.username);
    if (!mounted) return;
    setState(() => _memberships = result);
  }

  Future<void> _open(Route<void> route) async {
    await Navigator.of(context).push(route);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _memberships, _open);
}

Route<void> _createRoute(String username) =>
    blurDialogRoute<void>((_) => CreateServerScreen(username: username));

Route<void> _joinRoute(String username) =>
    blurDialogRoute<void>((_) => JoinServerScreen(username: username));

Route<void> _serverRoute(String username, ServerMembership m) =>
    MaterialPageRoute<void>(
      builder: (_) =>
          ServerHomeScreen(username: username, server: m.server, role: m.role),
    );

/// Beranda: sapaan, aksi cepat, dan server milik akun.
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.username,
    required this.onOpenServers,
  });

  final String username;
  final VoidCallback onOpenServers;

  @override
  Widget build(BuildContext context) {
    return _ServersLoader(
      username: username,
      builder: (context, memberships, open) {
        return _Page(
          children: [
            Text(
              'Halo, $username!',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apa rencanamu hari ini?',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _QuickActions(
              onCreate: () => open(_createRoute(username)),
              onJoin: () => open(_joinRoute(username)),
            ),
            const SizedBox(height: 28),
            _SectionHeader(
              title: 'Server saya',
              actionLabel: 'Lihat semua',
              onAction: onOpenServers,
            ),
            const SizedBox(height: 12),
            _ServerCards(
              memberships: memberships,
              limit: 6,
              onOpen: (m) => open(_serverRoute(username, m)),
            ),
            const SizedBox(height: 28),
            const _SectionHeader(title: 'Untukmu'),
            const SizedBox(height: 12),
            const _SoonCard(
              icon: Icons.badge_outlined,
              text:
                  'Kandidat dan peluang yang cocok denganmu akan tampil di '
                  'sini setelah fiturnya siap.',
            ),
          ],
        );
      },
    );
  }
}

/// Tab Server: semua server milik akun.
class ServersTab extends StatelessWidget {
  const ServersTab({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return _ServersLoader(
      username: username,
      builder: (context, memberships, open) {
        return _Page(
          children: [
            const Text(
              'Server',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Komunitas dan tim project tempatmu bergabung.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _QuickActions(
              onCreate: () => open(_createRoute(username)),
              onJoin: () => open(_joinRoute(username)),
            ),
            const SizedBox(height: 24),
            _ServerCards(
              memberships: memberships,
              onOpen: (m) => open(_serverRoute(username, m)),
            ),
          ],
        );
      },
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onCreate, required this.onJoin});

  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _ActionCard(
          icon: Icons.add_rounded,
          background: const Color(0x335865F2),
          title: 'Buat server',
          description: 'Jadi boss dan undang builder pakai token.',
          onTap: onCreate,
        ),
        _ActionCard(
          icon: Icons.vpn_key_outlined,
          background: const Color(0x33B69CFF),
          title: 'Gabung server',
          description: 'Punya token dari boss? Masukkan di sini.',
          onTap: onJoin,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.background,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kFieldBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.3,
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
    );
  }
}

class _ServerCards extends StatelessWidget {
  const _ServerCards({
    required this.memberships,
    required this.onOpen,
    this.limit,
  });

  final List<ServerMembership>? memberships;
  final ValueChanged<ServerMembership> onOpen;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final list = memberships;
    if (list == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (list.isEmpty) {
      return const _SoonCard(
        icon: Icons.dns_outlined,
        text:
            'Kamu belum bergabung di server mana pun. Buat server baru atau '
            'gabung pakai token.',
      );
    }
    final shown = limit == null ? list : list.take(limit!).toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final m in shown)
          _ServerCard(membership: m, onTap: () => onOpen(m)),
      ],
    );
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({required this.membership, required this.onTap});

  final ServerMembership membership;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final server = membership.server;
    final isBoss = membership.role == ServerRole.admin;
    return SizedBox(
      width: 200,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kFieldBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServerAvatar(
                  colorIndex: server.colorIndex,
                  iconIndex: server.iconIndex,
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  server.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isBoss ? 'Boss' : 'Builder',
                  style: TextStyle(
                    color: isBoss ? AppColors.accent : AppColors.textMuted,
                    fontSize: 12,
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

class _SoonCard extends StatelessWidget {
  const _SoonCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFieldBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
