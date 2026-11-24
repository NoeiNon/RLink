import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../data/mock_project_store.dart';
import '../data/mock_server_store.dart' show ServerException;
import '../models/project.dart';
import '../models/server.dart';
import '../../../widgets/auth_layout.dart' show PrimaryButton, kFieldBorder;
import '../../../widgets/app_feedback.dart';
import '../widgets/blueprint_gallery.dart';
import '../widgets/project_chips.dart';
import 'project_form_screen.dart' show TagEditor;

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
  final List<Blueprint> _photos = [];
  bool _busy = false;

  bool get _isBuilder => widget.role == ServerRole.builder;
  bool get _isAdmin => widget.role == ServerRole.admin;
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
      showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() => _run(
    () => MockProjectStore.claim(
      serverId: widget.serverId,
      projectId: _project.id,
      username: widget.username,
    ),
  );

  Future<void> _attach() async {
    final picked = await pickBlueprints(context, already: _photos.length);
    if (picked.isEmpty || !mounted) return;
    setState(() => _photos.addAll(picked));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty && _photos.isEmpty) return;
    final photos = List<Blueprint>.of(_photos);
    _input.clear();
    setState(_photos.clear);
    await _run(
      () => MockProjectStore.addUpdate(
        serverId: widget.serverId,
        projectId: _project.id,
        author: widget.username,
        text: text,
        photos: photos,
      ),
    );
  }

  Future<void> _addBlueprints() async {
    final picked = await pickBlueprints(
      context,
      already: _project.blueprints.length,
    );
    if (picked.isEmpty) return;
    await _run(
      () => MockProjectStore.addBlueprints(
        serverId: widget.serverId,
        projectId: _project.id,
        items: picked,
      ),
    );
  }

  Future<void> _removeBlueprint(int index) => _run(
    () => MockProjectStore.removeBlueprint(
      serverId: widget.serverId,
      projectId: _project.id,
      index: index,
    ),
  );

  Future<void> _editTags() async {
    var tags = List<String>.of(_project.tags);
    final ok = await showConfirmDialog(
      context,
      icon: Icons.sell_outlined,
      color: AppColors.accent,
      title: 'Atur tag',
      message: 'Tag membantu boss dan builder menyaring project.',
      confirmLabel: 'Simpan',
      body: TagEditor(tags: tags, onChanged: (v) => tags = v),
    );
    if (ok != true) return;
    await _run(
      () => MockProjectStore.setTags(
        serverId: widget.serverId,
        projectId: _project.id,
        tags: tags,
      ),
    );
  }

  Future<void> _accept() async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.check_circle_outline_rounded,
      color: kSuccessColor,
      title: 'Terima hasil kerja?',
      message:
          'Project akan ditandai Finished dan tidak bisa dikerjakan '
          'lagi oleh builder.',
      confirmLabel: 'Accept',
    );
    if (ok != true) return;
    await _run(
      () => MockProjectStore.accept(
        serverId: widget.serverId,
        projectId: _project.id,
      ),
    );
  }

  Future<void> _decline() async {
    final reason = TextEditingController();
    final ok = await showConfirmDialog(
      context,
      icon: Icons.highlight_off_rounded,
      color: kErrorColor,
      title: 'Tolak hasil kerja?',
      message:
          'Project kembali ke On Progress supaya builder bisa '
          'memperbaikinya. Tulis revisi yang diminta (opsional).',
      confirmLabel: 'Decline',
      body: TextField(
        controller: reason,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Contoh: atap sisi barat belum selesai',
        ),
      ),
    );
    final text = reason.text;
    reason.dispose();
    if (ok != true) return;
    await _run(
      () => MockProjectStore.decline(
        serverId: widget.serverId,
        projectId: _project.id,
        reviewer: widget.username,
        reason: text,
      ),
    );
  }

  Future<void> _markDone() async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.task_alt_rounded,
      color: kSuccessColor,
      title: 'Tandai selesai?',
      message:
          'Project dikirim ke boss untuk diperiksa. Kamu tidak bisa '
          'mengirim update lagi sampai ada keputusan.',
      confirmLabel: 'Ya, selesai',
    );
    if (ok != true) return;
    await _run(
      () => MockProjectStore.markDone(
        serverId: widget.serverId,
        projectId: _project.id,
        username: widget.username,
      ),
    );
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
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    ),
  );

  Widget _actions() {
    final p = _project;
    Widget note(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
    );

    if (_isAdmin) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            if (p.status == ProjectStatus.review) ...[
              note(
                'Builder menandai project ini selesai. '
                'Periksa progress, lalu putuskan.',
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _decline,
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Accept',
                      loading: _busy,
                      onPressed: _accept,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _busy ? null : _editTags,
                icon: const Icon(Icons.sell_outlined, size: 18),
                label: const Text('Atur tag'),
              ),
            ),
          ],
        ),
      );
    }
    if (!_isBuilder) return const SizedBox.shrink();
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
      return note('Menunggu boss memeriksa pekerjaanmu.');
    }
    if (p.status == ProjectStatus.finished) {
      return note('Project ini sudah selesai.');
    }
    if (_isWorker) return const SizedBox.shrink();
    if (p.status == ProjectStatus.review) {
      return note('Project ini sedang direview boss.');
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

  List<Widget> _progress() {
    final p = _project;
    return [
      Text(
        'PROGRESS (${p.updates.length})',
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      if (p.updates.isEmpty)
        const Text(
          'Belum ada update dari worker.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      for (final u in p.updates)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kFieldBorder),
          ),
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
              if (u.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  u.text,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
              if (u.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                BlueprintGallery(items: u.photos),
              ],
            ],
          ),
        ),
    ];
  }

  Widget _composer() {
    final canPost =
        _isBuilder && _isWorker && _project.status == ProjectStatus.onProgress;
    if (!canPost) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: kFieldBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_photos.isNotEmpty) ...[
              BlueprintGallery(
                items: _photos,
                onRemove: (i) => setState(() => _photos.removeAt(i)),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                IconButton(
                  tooltip: 'Lampirkan foto lapangan',
                  onPressed: _busy ? null : _attach,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                ),
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Jelaskan progress project...',
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _project;
    final info = <Widget>[
      Text(
        p.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          LabelChip(label: p.status.label, color: statusColor(p.status)),
          for (final t in p.displayTags)
            LabelChip(label: t, color: tagColor(t)),
        ],
      ),
      const SizedBox(height: 14),
      _card(
        'INFO',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line('Dari', p.from),
            _line('Payment', p.paymentLabel),
            _line('Deadline', formatDate(p.deadline)),
            _line('Worker', '${p.workers.length}/${p.maxWorkers}'),
          ],
        ),
      ),
      _card(
        'DETAIL',
        Text(p.detail, style: const TextStyle(color: AppColors.textPrimary)),
      ),
      if (p.blueprints.isNotEmpty || _isAdmin)
        _card(
          'BLUEPRINT (${p.blueprints.length})',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.blueprints.isEmpty)
                const Text(
                  'Belum ada blueprint.',
                  style: TextStyle(color: AppColors.textMuted),
                )
              else
                BlueprintGallery(
                  items: p.blueprints,
                  onRemove: _isAdmin ? _removeBlueprint : null,
                ),
              if (_isAdmin)
                TextButton.icon(
                  onPressed: _busy ? null : _addBlueprints,
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 18,
                  ),
                  label: const Text('Tambah gambar'),
                ),
            ],
          ),
        ),
      if (p.workers.isNotEmpty)
        _card(
          'WORKER',
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final w in p.workers)
                LabelChip(label: w, color: AppColors.primary),
            ],
          ),
        ),
      _actions(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Project')),
      body: LayoutBuilder(
        builder: (context, box) {
          // Layar lebar: info di kiri, progress worker di kanan.
          if (box.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: info,
                  ),
                ),
                const VerticalDivider(width: 1, color: kFieldBorder),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: _progress(),
                        ),
                      ),
                      _composer(),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [...info, ..._progress()],
                ),
              ),
              _composer(),
            ],
          );
        },
      ),
    );
  }
}
