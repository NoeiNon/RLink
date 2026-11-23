import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/mock_server_store.dart';
import '../../models/server.dart';
import '../../models/server_content.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/auth_layout.dart';

String _formatDateTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.day)}/${two(time.month)}/${time.year} '
      '${two(time.hour)}:${two(time.minute)}';
}

/// SOP kerja server, berupa satu teks panjang seperti README.
/// Admin bisa mengedit dan menyimpan langsung. Builder hanya membaca
/// (seperti catatan patch note), tanpa tombol edit.
class SopScreen extends StatefulWidget {
  const SopScreen({
    super.key,
    required this.server,
    required this.isAdmin,
    this.embedded = false,
  });

  final ServerInfo server;
  final bool isAdmin;

  /// true = dipakai di dalam halaman server (tanpa Scaffold/AppBar sendiri).
  final bool embedded;

  @override
  State<SopScreen> createState() => _SopScreenState();
}

class _SopScreenState extends State<SopScreen> {
  final _controller = TextEditingController();

  SopDocument? _document;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final document = await MockServerStore.getSop(widget.server.id);
    if (!mounted) return;
    setState(() {
      _document = document;
      _loading = false;
    });
  }

  void _startEdit() {
    _controller.text = _document?.text ?? '';
    setState(() => _editing = true);
  }

  void _cancelEdit() => setState(() => _editing = false);

  Future<void> _save() async {
    setState(() => _saving = true);
    final document = await MockServerStore.saveSop(
      serverId: widget.server.id,
      text: _controller.text,
    );
    if (!mounted) return;
    setState(() {
      _document = document;
      _editing = false;
      _saving = false;
    });
    showToast(context, 'SOP disimpan', error: false);
  }

  List<Widget> _buildActions() {
    if (_loading) return const [];

    if (_editing) {
      return [
        TextButton(
          onPressed: _saving ? null : _cancelEdit,
          child: const Text('Batal'),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ),
      ];
    }

    if (widget.isAdmin) {
      return [
        IconButton(
          tooltip: 'Edit SOP',
          icon: const Icon(Icons.edit_outlined),
          onPressed: _startEdit,
        ),
      ];
    }
    return const [];
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_editing) return _buildEditor();
    return _buildReader();
  }

  Widget _buildEditor() {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: 15, height: 1.5),
            decoration: InputDecoration(
              hintText: 'Tulis SOP di sini...',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.all(16),
              border: border(kFieldBorder),
              enabledBorder: border(kFieldBorder),
              focusedBorder: border(AppColors.primary, 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReader() {
    final document = _document;
    final text = document?.text ?? '';
    final updatedAt = document?.updatedAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (updatedAt != null) ...[
                Text(
                  'Terakhir diperbarui ${_formatDateTime(updatedAt)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (text.isEmpty)
                Text(
                  widget.isAdmin
                      ? 'Belum ada SOP. Tekan ikon pensil di kanan atas '
                            'untuk mulai menulis.'
                      : 'Boss belum menulis SOP.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                )
              else
                SelectableText(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'SOP',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ..._buildActions(),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('SOP'),
        actions: _buildActions(),
      ),
      body: _buildBody(),
    );
  }
}
