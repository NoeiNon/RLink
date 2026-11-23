import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/mock_announcement_store.dart';
import '../../data/mock_server_store.dart' show ServerException;
import '../../models/server.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../../widgets/auth_split_layout.dart' show compactInputDecoration;

String _fmt(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
}

/// Pengumuman dari boss. Boss bisa membuat dan menghapus, builder membaca.
class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({
    super.key,
    required this.server,
    required this.username,
    required this.isAdmin,
  });

  final ServerInfo server;
  final String username;
  final bool isAdmin;

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  bool _composing = false;
  bool _posting = false;
  bool _loading = true;
  List<Announcement> _items = const [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // Muat ulang berkala supaya pengumuman baru dari boss muncul di member.
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  Future<void> _load() async {
    final items = await MockAnnouncementStore.list(widget.server.id);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_title.text.trim().isEmpty || _text.text.trim().isEmpty) {
      showToast(context, 'Judul dan isi pengumuman wajib diisi.');
      return;
    }
    setState(() => _posting = true);
    try {
      await MockAnnouncementStore.post(
        serverId: widget.server.id,
        title: _title.text,
        text: _text.text,
        author: widget.username,
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() => _posting = false);
      showToast(context, e.message);
      return;
    }
    if (!mounted) return;
    _title.clear();
    _text.clear();
    setState(() {
      _composing = false;
      _posting = false;
    });
    showToast(context, 'Pengumuman diposting', error: false);
    await _load();
  }

  Future<void> _delete(Announcement a) async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      color: const Color(0xFFED4245),
      title: 'Hapus pengumuman?',
      message: '"${a.title}" akan dihapus untuk semua anggota.',
      confirmLabel: 'Hapus',
    );
    if (ok != true || !mounted) return;
    try {
      await MockAnnouncementStore.delete(widget.server.id, a.id);
    } on ServerException catch (e) {
      if (mounted) showToast(context, e.message);
      return;
    }
    await _load();
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            style: const TextStyle(fontSize: 13.5),
            decoration: compactInputDecoration(label: 'Judul'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: 3,
            maxLines: 8,
            style: const TextStyle(fontSize: 13.5),
            decoration: compactInputDecoration(label: 'Isi pengumuman'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _composing = false),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 6),
              FilledButton(
                onPressed: _posting ? null : _post,
                child: const Text('Posting'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(Announcement a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kFieldBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${a.author} · ${_fmt(a.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  a.text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isAdmin)
            IconButton(
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
              onPressed: () => _delete(a),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Announcement',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.isAdmin && !_composing)
                  FilledButton.icon(
                    onPressed: () => setState(() => _composing = true),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Buat'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_composing) ...[_composer(), const SizedBox(height: 12)],
            if (items.isEmpty && !_composing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  widget.isAdmin
                      ? 'Belum ada pengumuman. Tekan "Buat" untuk memulai.'
                      : 'Belum ada pengumuman dari boss.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            for (final a in items) _card(a),
          ],
        ),
      ),
    );
  }
}
