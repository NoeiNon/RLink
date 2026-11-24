import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../data/mock_server_store.dart';
import '../models/server.dart';
import '../../../widgets/auth_layout.dart' show kFieldBorder;

/// Daftar anggota di sisi kanan Beranda, dikelompokkan seperti Discord.
class MembersSidebar extends StatefulWidget {
  const MembersSidebar({
    super.key,
    required this.server,
    required this.username,
  });

  final ServerInfo server;
  final String username;

  @override
  State<MembersSidebar> createState() => _MembersSidebarState();
}

class _MembersSidebarState extends State<MembersSidebar> {
  List<ServerMember>? _members;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _sync());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MembersSidebar old) {
    super.didUpdateWidget(old);
    if (old.server.id != widget.server.id) _load();
  }

  Future<void> _load() async {
    final list = await MockServerStore.getMembers(widget.server.id);
    if (!mounted) return;
    setState(() => _members = list);
  }

  Future<void> _sync() async {
    try {
      final list = await MockServerStore.getMembers(widget.server.id);
      if (!mounted) return;
      setState(() => _members = list);
    } catch (_) {}
  }

  Widget _group(String title, List<ServerMember> items, Color nameColor) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
          child: Text(
            '${title.toUpperCase()} — ${items.length}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        for (final m in items)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: nameColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = _members ?? const <ServerMember>[];
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: kFieldBorder)),
      ),
      child: _members == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                _group(
                  'Founder',
                  members.where((m) => m.role == ServerRole.admin).toList(),
                  AppColors.accent,
                ),
                _group(
                  'Builder',
                  members.where((m) => m.role != ServerRole.admin).toList(),
                  AppColors.textPrimary,
                ),
              ],
            ),
    );
  }
}
