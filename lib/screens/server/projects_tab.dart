import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/mock_project_store.dart';
import '../../models/project.dart';
import '../../models/server.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../../widgets/project_chips.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

/// Daftar project ala forum Discord: cari, filter, lalu buka detail.
class ProjectsTab extends StatefulWidget {
  const ProjectsTab({
    super.key,
    required this.server,
    required this.username,
    required this.role,
  });

  final ServerInfo server;
  final String username;
  final ServerRole role;

  @override
  State<ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<ProjectsTab> {
  List<Project>? _projects;
  String _query = '';
  String _filter = 'all';

  bool get _isBuilder => widget.role == ServerRole.builder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await MockProjectStore.list(widget.server.id);
    if (!mounted) return;
    setState(() => _projects = list);
  }

  List<Project> _visible(List<Project> all) {
    final q = _query.trim().toLowerCase();
    return all.where((p) {
      if (q.isNotEmpty && !p.title.toLowerCase().contains(q)) return false;
      if (_filter == 'mine') return p.hasWorker(widget.username);
      if (_filter.startsWith('status:')) {
        return p.status.name == _filter.substring(7);
      }
      if (_filter.startsWith('tag:')) {
        return p.tags.contains(_filter.substring(4));
      }
      return true;
    }).toList();
  }

  Future<void> _open(Project project) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProjectDetailScreen(
          serverId: widget.server.id,
          project: project,
          username: widget.username,
          role: widget.role,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _create(List<String> knownTags) async {
    final created = await Navigator.of(context).push<Project>(
      MaterialPageRoute<Project>(
        builder: (_) => ProjectFormScreen(
          serverId: widget.server.id,
          author: widget.username,
          knownTags: knownTags,
        ),
      ),
    );
    if (created != null && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final all = _projects;
    if (all == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final tags = {for (final p in all) ...p.tags}.toList()..sort();
    final shown = _visible(all);

    final filters = <(String, String)>[
      ('all', 'Semua'),
      if (_isBuilder) ('mine', 'Project saya'),
      for (final s in ProjectStatus.values) ('status:${s.name}', s.label),
      for (final t in tags) ('tag:$t', '#$t'),
    ];

    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Cari project...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kFieldBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kFieldBorder),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final (key, label) = filters[i];
              return ChoiceChip(
                label: Text(label),
                selected: _filter == key,
                onSelected: (_) => setState(() => _filter = key),
              );
            },
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      all.isEmpty
                          ? 'Belum ada project di server ini.'
                          : 'Tidak ada project yang cocok.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, _isBuilder ? 16 : 88),
                    itemCount: shown.length,
                    itemBuilder: (_, i) => _ProjectCard(
                      project: shown[i],
                      onTap: () => _open(shown[i]),
                    ),
                  ),
                ),
        ),
      ],
    );

    if (_isBuilder) return body;
    // Admin: tombol "Project baru" (seperti New Post di forum Discord).
    return Stack(
      children: [
        body,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _create(tags),
            icon: const Icon(Icons.add),
            label: const Text('Project baru'),
          ),
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({required this.project, required this.onTap});

  final Project project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = project.updates.length;
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kFieldBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  LabelChip(
                    label: project.status.label,
                    color: statusColor(project.status),
                  ),
                  for (final tag in project.tags)
                    LabelChip(label: tag, color: AppColors.accent),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${project.author} · $n update · ${timeAgo(project.createdAt)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
