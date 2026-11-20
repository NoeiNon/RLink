import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/mock_project_store.dart';
import '../../data/mock_server_store.dart' show ServerException;
import '../../models/project.dart';
import '../../models/server.dart';
import '../../widgets/auth_layout.dart' show PrimaryButton, kFieldBorder;
import '../../widgets/project_chips.dart';

/// Detail project: info, worker, aksi builder, dan thread progress.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.serverId,
    required this.project,
    required this.username,
    required this.role,
  });

  final String serverId;
  final Project project;
  final String username;
  final ServerRole role;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project = widget.project;
  final _input = TextEditingController();
  bool _busy = false;

  bool get _isBuilder => widget.role == ServerRole.builder;
  bool get _isWorker => _project.hasWorker(widget.username);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _run(Future<Project> Function() action) async {
    setState(() => _busy = true);
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() => _project = updated);
    } on ServerException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() => _run(() => MockProjectStore.claim(
        serverId: widget.serverId,
        projectId: _project.id,
        username: widget.username,
      ));

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    await _run(() => MockProjectStore.addUpdate(
          serverId: widget.serverId,
          projectId: _project.id,
          author: widget.username,
          text: text,
        ));
  }

  Future<void> _markDone() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as done?'),
        content: const Text(
          'Project akan dikirim ke admin untuk diperiksa. '
          'Kamu tidak bisa mengirim update lagi sampai ada keputusan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, selesai'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() => MockProjectStore.markDone(
          serverId: widget.serverId,
          projectId: _project.id,
          username: widget.username,
        ));
  }

  Widget _card(String title, Widget child) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kFieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _line(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text.rich(TextSpan(children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ])),
      );

  Widget _actions() {
    if (!_isBuilder) return const SizedBox.shrink();
    final p = _project;
    Widget note(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
        );

    if (_isWorker && p.status == ProjectStatus.onProgress) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _busy ? null : _markDone,
            child: const Text('Mark as done'),
          ),
        ),
      );
    }
    if (_isWorker && p.status == ProjectStatus.review) {
      return note('Menunggu admin memeriksa pekerjaanmu.');
    }
    if (p.status == ProjectStatus.finished) {
      return note('Project ini sudah selesai.');
    }
    if (_isWorker) return const SizedBox.shrink();
    if (p.status == ProjectStatus.review) {
      return note('Project ini sedang direview admin.');
    }
    if (p.isFull) return note('Slot worker sudah penuh.');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PrimaryButton(
        label: 'Claim project',
        loading: _busy,
        onPressed: _claim,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _project;
    final canPost =
        _isBuilder && _isWorker && p.status == ProjectStatus.onProgress;

    return Scaffold(
      appBar: AppBar(title: const Text('Project')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  p.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  LabelChip(
                    label: p.status.label,
                    color: statusColor(p.status),
                  ),
                  for (final t in p.tags)
                    LabelChip(label: t, color: AppColors.accent),
                ]),
                const SizedBox(height: 14),
                _card(
                  'INFO',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line('Dari', p.from),
                      _line('Payment', p.payment),
                      _line('Deadline', p.deadline),
                      _line('Worker', '${p.workers.length}/${p.maxWorkers}'),
                    ],
                  ),
                ),
                _card(
                  'DETAIL',
                  Text(
                    p.detail,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                if (p.workers.isNotEmpty)
                  _card(
                    'WORKER',
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final w in p.workers)
                        LabelChip(label: w, color: AppColors.primary),
                    ]),
                  ),
                _actions(),
                _card(
                  'PROGRESS (${p.updates.length})',
                  p.updates.isEmpty
                      ? const Text(
                          'Belum ada update.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final u in p.updates)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${u.author} · ${timeAgo(u.sentAt)}',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      u.text,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          if (canPost)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Tulis update progress...',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
