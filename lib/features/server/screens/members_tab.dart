import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../data/mock_server_store.dart';
import '../models/server.dart';
import '../../../widgets/auth_layout.dart' show kFieldBorder;
import '../widgets/project_chips.dart';

/// Daftar anggota server (hanya lihat). Admin server tampil sebagai Founder.
class MembersTab extends StatefulWidget {
  const MembersTab({super.key, required this.server, required this.username});

  final ServerInfo server;
  final String username;

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  List<ServerMember>? _members;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await MockServerStore.getMembers(widget.server.id);
    if (!mounted) return;
    setState(() => _members = list);
  }

  @override
  Widget build(BuildContext context) {
    final members = _members;
    if (members == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final founders = members.where((m) => m.role == ServerRole.admin).toList();
    final builders = members.where((m) => m.role != ServerRole.admin).toList();

    Widget section(String title, List<ServerMember> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                '$title — ${items.length}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final m in items)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kFieldBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        m.name.toLowerCase() ==
                                widget.username.trim().toLowerCase()
                            ? '${m.name} (kamu)'
                            : m.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    LabelChip(
                      label:
                          m.role == ServerRole.admin ? 'Founder' : 'Builder',
                      color: m.role == ServerRole.admin
                          ? AppColors.accent
                          : AppColors.primary,
                    ),
                  ],
                ),
              ),
          ],
        );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          section('Founder', founders),
          section('Builder', builders),
        ],
      ),
    );
  }
}
