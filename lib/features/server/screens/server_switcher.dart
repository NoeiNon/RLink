import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../data/mock_server_store.dart';
import '../models/server.dart';
import '../../../widgets/auth_layout.dart';
import '../../../widgets/compact_card_page.dart' show blurDialogRoute;
import '../widgets/server_avatar.dart';
import 'create_server_screen.dart';
import 'join_server_screen.dart';
import 'server_home_screen.dart';

/// Tombol nama server di atas layar. Ditekan, muncul daftar server milik
/// akun ini (dropdown, seperti dashboard bot) untuk berpindah server, plus
/// pintasan Buat server dan Gabung server beserta sisa kuotanya.
class ServerSwitcher extends StatelessWidget {
  const ServerSwitcher({
    super.key,
    required this.username,
    required this.current,
    required this.memberships,
    this.fill = false,
  });

  final String username;
  final ServerInfo current;
  final List<ServerMembership> memberships;

  /// true = melebar penuh (dipakai di bagian atas sidebar, seperti Discord).
  final bool fill;

  void _onSelected(BuildContext context, String value) {
    final navigator = Navigator.of(context);

    if (value == 'create') {
      navigator.push(
        blurDialogRoute<void>((_) => CreateServerScreen(username: username)),
      );
      return;
    }

    if (value == 'join') {
      navigator.push(
        blurDialogRoute<void>((_) => JoinServerScreen(username: username)),
      );
      return;
    }

    if (value.startsWith('server:')) {
      final id = value.substring('server:'.length);
      if (id == current.id) return;

      for (final membership in memberships) {
        if (membership.server.id != id) continue;
        // Ganti halaman server saat ini; beranda utama tetap ada di bawahnya
        // supaya tombol "Beranda" tetap bisa kembali.
        navigator.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ServerHomeScreen(
              username: username,
              server: membership.server,
              role: membership.role,
            ),
          ),
        );
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final created = memberships.where((m) => m.role == ServerRole.admin).length;
    final joined = memberships
        .where((m) => m.role == ServerRole.builder)
        .length;
    final canCreate = created < MockServerStore.maxCreated;
    final canJoin = joined < MockServerStore.maxJoined;

    return PopupMenuButton<String>(
      tooltip: 'Ganti server',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kFieldBorder),
      ),
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
      onSelected: (value) => _onSelected(context, value),
      itemBuilder: (context) => [
        for (final membership in memberships)
          PopupMenuItem<String>(
            value: 'server:${membership.server.id}',
            height: 56,
            child: _ServerRow(
              membership: membership,
              selected: membership.server.id == current.id,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'create',
          enabled: canCreate,
          child: _ActionRow(
            icon: Icons.add_rounded,
            label: 'Buat server',
            count: '$created/${MockServerStore.maxCreated}',
            enabled: canCreate,
          ),
        ),
        PopupMenuItem<String>(
          value: 'join',
          enabled: canJoin,
          child: _ActionRow(
            icon: Icons.vpn_key_outlined,
            label: 'Gabung server',
            count: '$joined/${MockServerStore.maxJoined}',
            enabled: canJoin,
          ),
        ),
      ],
      child: _Pill(server: current, fill: fill),
    );
  }
}

/// Bentuk tombol (pil) yang selalu terlihat di atas layar.
class _Pill extends StatelessWidget {
  const _Pill({required this.server, this.fill = false});

  final ServerInfo server;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final name = Text(
      server.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fill ? 14 : 15,
        fontWeight: FontWeight.w700,
      ),
    );

    return Container(
      padding: fill
          ? const EdgeInsets.fromLTRB(8, 8, 8, 8)
          : const EdgeInsets.fromLTRB(6, 6, 10, 6),
      decoration: BoxDecoration(
        color: fill ? const Color(0x1AFFFFFF) : AppColors.surface,
        borderRadius: BorderRadius.circular(fill ? 12 : 24),
        border: Border.all(color: kFieldBorder),
      ),
      child: Row(
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ServerAvatar(
            colorIndex: server.colorIndex,
            iconIndex: server.iconIndex,
            size: fill ? 30 : 28,
          ),
          const SizedBox(width: 8),
          fill ? Expanded(child: name) : Flexible(child: name),
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ServerRow extends StatelessWidget {
  const _ServerRow({required this.membership, required this.selected});

  final ServerMembership membership;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isAdmin = membership.role == ServerRole.admin;

    return Row(
      children: [
        ServerAvatar(
          colorIndex: membership.server.colorIndex,
          iconIndex: membership.server.iconIndex,
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            membership.server.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isAdmin ? 'Boss' : 'Builder',
          style: TextStyle(
            color: isAdmin ? const Color(0xFFB5BCFF) : const Color(0xFF6FD08C),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (selected) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_rounded, size: 18, color: AppColors.accent),
        ],
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.enabled,
  });

  final IconData icon;
  final String label;
  final String count;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.textPrimary : AppColors.textMuted;

    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          enabled ? count : '$count penuh',
          style: TextStyle(
            color: enabled ? AppColors.textMuted : kErrorColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
