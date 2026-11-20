import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../data/mock_project_store.dart';
import '../../data/mock_server_store.dart' show ServerException;
import '../../models/project.dart';
import '../../widgets/auth_layout.dart' show PrimaryButton;
import '../../widgets/blueprint_gallery.dart';

const kDefaultTags = ['Urgent', 'Delayed'];

/// Form admin untuk membuat project baru (seperti "New Post" di forum).
class ProjectFormScreen extends StatefulWidget {
  const ProjectFormScreen({
    super.key,
    required this.serverId,
    required this.author,
    this.knownTags = const [],
  });

  final String serverId;
  final String author;
  final List<String> knownTags;

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _from = TextEditingController();
  final _amount = TextEditingController();
  final _paymentNote = TextEditingController();
  final _deadline = TextEditingController();
  final _detail = TextEditingController();
  int _maxWorkers = 1;
  List<String> _tags = [];
  final List<Blueprint> _blueprints = [];
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [
      _title,
      _from,
      _amount,
      _paymentNote,
      _deadline,
      _detail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final Project created = await MockProjectStore.create(
        serverId: widget.serverId,
        author: widget.author,
        title: _title.text,
        from: _from.text,
        paymentAmount: int.parse(_amount.text.replaceAll('.', '')),
        paymentNote: _paymentNote.text,
        detail: _detail.text,
        deadline: _deadline.text,
        maxWorkers: _maxWorkers,
        tags: _tags,
        blueprints: _blueprints,
      );
      if (!mounted) return;
      Navigator.pop(context, created);
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    int minLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          validator: _required,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Future<void> _pickBlueprints() async {
    final picked = await pickBlueprints(context, already: _blueprints.length);
    if (picked.isEmpty || !mounted) return;
    setState(() => _blueprints.addAll(picked));
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = {...kDefaultTags, ...widget.knownTags}.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Project baru')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _field(_title, 'Judul project'),
                  _field(_from, 'Dari (pemberi project)'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_ThousandsFormatter()],
                      validator: (v) {
                        final n = int.tryParse((v ?? '').replaceAll('.', ''));
                        return (n == null || n <= 0)
                            ? 'Isi nominal payment'
                            : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Payment',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _paymentNote,
                      maxLength: 40,
                      decoration: const InputDecoration(
                        labelText: 'Catatan payment (opsional)',
                        hintText: 'mis. sekitar, bisa nego',
                      ),
                    ),
                  ),
                  _field(_deadline, 'Deadline (mis. 3 minggu)'),
                  _field(_detail, 'Detail dan lokasi',
                      minLines: 4, maxLines: 10),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Maksimal worker',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      IconButton(
                        onPressed: _maxWorkers > 1
                            ? () => setState(() => _maxWorkers--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_maxWorkers',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: _maxWorkers < 10
                            ? () => setState(() => _maxWorkers++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'BLUEPRINT (opsional)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_blueprints.isNotEmpty) ...[
                    BlueprintGallery(
                      items: _blueprints,
                      onRemove: (i) => setState(() => _blueprints.removeAt(i)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: _pickBlueprints,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Tambah gambar blueprint'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'TAG (opsional)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TagEditor(
                    tags: _tags,
                    suggestions: suggestions,
                    onChanged: (v) => _tags = v,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Publish project',
                    loading: _busy,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Editor tag bebas: ketik tag baru atau pilih dari saran.
class TagEditor extends StatefulWidget {
  const TagEditor({
    super.key,
    required this.tags,
    required this.onChanged,
    this.suggestions = kDefaultTags,
  });

  final List<String> tags;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<TagEditor> {
  static const _maxTags = 5;
  late List<String> _tags = List<String>.of(widget.tags);
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  bool _has(String tag) =>
      _tags.any((t) => t.toLowerCase() == tag.toLowerCase());

  void _add(String raw) {
    var tag = raw.trim();
    while (tag.startsWith('#')) {
      tag = tag.substring(1).trim();
    }
    if (tag.length > 20) tag = tag.substring(0, 20);
    if (tag.isEmpty || _has(tag) || _tags.length >= _maxTags) return;
    setState(() => _tags = [..._tags, tag]);
    _input.clear();
    widget.onChanged(_tags);
  }

  void _remove(String tag) {
    setState(() => _tags = _tags.where((t) => t != tag).toList());
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final free = widget.suggestions.where((s) => !_has(s)).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in _tags)
                InputChip(label: Text(t), onDeleted: () => _remove(t)),
            ],
          ),
        if (free.isNotEmpty && _tags.length < _maxTags) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in free)
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(s),
                  onPressed: () => _add(s),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: _input,
          enabled: _tags.length < _maxTags,
          textInputAction: TextInputAction.done,
          onSubmitted: _add,
          decoration: InputDecoration(
            hintText: _tags.length < _maxTags
                ? 'Tag baru, lalu Enter'
                : 'Maksimal $_maxTags tag',
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _add(_input.text),
            ),
          ),
        ),
      ],
    );
  }
}

/// Angka saja, otomatis diberi titik ribuan (21000 -> 21.000).
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 9) digits = digits.substring(0, 9);
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
