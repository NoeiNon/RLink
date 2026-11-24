import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/cv_store.dart';
import '../../models/cv.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../../widgets/auth_split_layout.dart' show compactInputDecoration;

/// Editor CV. Disimpan per akun dan hanya terlihat oleh pemiliknya sampai
/// dia apply ke sebuah company (lalu salinannya terkirim ke boss).
class CvScreen extends StatefulWidget {
  const CvScreen({super.key, required this.username});

  final String username;

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  final _fullName = TextEditingController();
  final _headline = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _summary = TextEditingController();
  final _skills = TextEditingController();
  final _languages = TextEditingController();
  final _certs = TextEditingController();
  final _links = TextEditingController();

  List<CvExperience> _experiences = [];
  List<CvEducation> _educations = [];
  bool _loading = true;
  bool _saving = false;

  List<TextEditingController> get _all => [
    _fullName,
    _headline,
    _email,
    _phone,
    _city,
    _summary,
    _skills,
    _languages,
    _certs,
    _links,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    CvData? cv;
    try {
      cv = await CvStore.load(widget.username);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      if (cv != null) {
        _fullName.text = cv.fullName;
        _headline.text = cv.headline;
        _email.text = cv.email;
        _phone.text = cv.phone;
        _city.text = cv.city;
        _summary.text = cv.summary;
        _skills.text = cv.skills.join(', ');
        _languages.text = cv.languages.join(', ');
        _certs.text = cv.certifications.join('\n');
        _links.text = cv.links.join('\n');
        _experiences = [...cv.experiences];
        _educations = [...cv.educations];
      }
      _loading = false;
    });
  }

  static List<String> _split(String text, Pattern separator) => [
    for (final part in text.split(separator))
      if (part.trim().isNotEmpty) part.trim(),
  ];

  CvData _build() => CvData(
    fullName: _fullName.text.trim(),
    headline: _headline.text.trim(),
    email: _email.text.trim(),
    phone: _phone.text.trim(),
    city: _city.text.trim(),
    summary: _summary.text.trim(),
    experiences: _experiences,
    educations: _educations,
    skills: _split(_skills.text, RegExp(r'[,\n]')),
    languages: _split(_languages.text, RegExp(r'[,\n]')),
    certifications: _split(_certs.text, '\n'),
    links: _split(_links.text, '\n'),
  );

  Future<void> _save() async {
    if (_fullName.text.trim().isEmpty) {
      showToast(context, 'Nama lengkap wajib diisi.');
      return;
    }
    setState(() => _saving = true);
    try {
      await CvStore.save(widget.username, _build());
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showToast(context, 'Gagal menyimpan CV: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    showToast(context, 'CV disimpan', error: false);
    Navigator.of(context).pop(true);
  }

  /// Dialog isian untuk satu item (pengalaman atau pendidikan).
  Future<List<String>?> _askItem(
    String title,
    List<(String, bool)> fields,
    List<String> initial,
  ) async {
    final controllers = [
      for (final v in initial) TextEditingController(text: v),
    ];
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(fontSize: 15)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < fields.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[i],
                      minLines: fields[i].$2 ? 3 : 1,
                      maxLines: fields[i].$2 ? 6 : 1,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: compactInputDecoration(label: fields[i].$1),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controllers.first.text.trim().isEmpty) return;
              Navigator.pop(ctx, [for (final c in controllers) c.text.trim()]);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    for (final c in controllers) {
      c.dispose();
    }
    return result;
  }

  Future<void> _editExperience([int? index]) async {
    final old = index == null ? null : _experiences[index];
    final v = await _askItem(
      old == null ? 'Tambah pengalaman' : 'Ubah pengalaman',
      const [
        ('Posisi / jabatan', false),
        ('Perusahaan', false),
        ('Periode (mis. Jan 2022 – Sekarang)', false),
        ('Deskripsi singkat', true),
      ],
      [old?.role ?? '', old?.company ?? '', old?.period ?? '', old?.description ?? ''],
    );
    if (v == null) return;
    final item = CvExperience(
      role: v[0],
      company: v[1],
      period: v[2],
      description: v[3],
    );
    setState(() {
      if (index == null) {
        _experiences = [..._experiences, item];
      } else {
        _experiences[index] = item;
      }
    });
  }

  Future<void> _editEducation([int? index]) async {
    final old = index == null ? null : _educations[index];
    final v = await _askItem(
      old == null ? 'Tambah pendidikan' : 'Ubah pendidikan',
      const [
        ('Sekolah / universitas', false),
        ('Jurusan / jenjang', false),
        ('Periode (mis. 2018 – 2022)', false),
      ],
      [old?.school ?? '', old?.major ?? '', old?.period ?? ''],
    );
    if (v == null) return;
    final item = CvEducation(school: v[0], major: v[1], period: v[2]);
    setState(() {
      if (index == null) {
        _educations = [..._educations, item];
      } else {
        _educations[index] = item;
      }
    });
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    TextInputType? type,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: lines > 1 ? TextInputType.multiline : type,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 3,
        style: const TextStyle(fontSize: 13.5),
        decoration: compactInputDecoration(label: label, helper: helper),
      ),
    );
  }

  Widget _section(String title, List<Widget> children, {Widget? action}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _itemRow({
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 17),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Hapus',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline_rounded, size: 17),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _addButton(String label, VoidCallback onTap) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.add_rounded, size: 16),
    label: Text(label),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'CV',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _loading || _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  children: [
                    _section('Data diri', [
                      _field(_fullName, 'Nama lengkap'),
                      _field(
                        _headline,
                        'Posisi yang dicari / jabatan',
                        helper: 'Mis. Backend Developer, Desainer Grafis',
                      ),
                      _field(
                        _email,
                        'Email',
                        type: TextInputType.emailAddress,
                      ),
                      _field(_phone, 'No. telepon', type: TextInputType.phone),
                      _field(_city, 'Kota domisili'),
                    ]),
                    _section('Ringkasan', [
                      _field(
                        _summary,
                        'Tentang kamu dalam beberapa kalimat',
                        lines: 4,
                      ),
                    ]),
                    _section(
                      'Pengalaman kerja',
                      [
                        if (_experiences.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Belum ada. Fresh graduate? Cantumkan magang, '
                              'proyek, atau organisasi.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        for (var i = 0; i < _experiences.length; i++)
                          _itemRow(
                            title: _experiences[i].role,
                            subtitle: [
                              _experiences[i].company,
                              _experiences[i].period,
                            ].where((e) => e.isNotEmpty).join(' · '),
                            onEdit: () => _editExperience(i),
                            onDelete: () =>
                                setState(() => _experiences.removeAt(i)),
                          ),
                      ],
                      action: _addButton('Tambah', _editExperience),
                    ),
                    _section(
                      'Pendidikan',
                      [
                        for (var i = 0; i < _educations.length; i++)
                          _itemRow(
                            title: _educations[i].school,
                            subtitle: [
                              _educations[i].major,
                              _educations[i].period,
                            ].where((e) => e.isNotEmpty).join(' · '),
                            onEdit: () => _editEducation(i),
                            onDelete: () =>
                                setState(() => _educations.removeAt(i)),
                          ),
                      ],
                      action: _addButton('Tambah', _editEducation),
                    ),
                    _section('Keahlian & bahasa', [
                      _field(
                        _skills,
                        'Keahlian',
                        helper: 'Pisahkan dengan koma',
                      ),
                      _field(
                        _languages,
                        'Bahasa',
                        helper: 'Mis. Indonesia (native), Inggris (aktif)',
                      ),
                    ]),
                    _section('Sertifikat & portofolio', [
                      _field(
                        _certs,
                        'Sertifikat / pelatihan',
                        lines: 2,
                        helper: 'Satu per baris',
                      ),
                      _field(
                        _links,
                        'Tautan (LinkedIn, GitHub, portofolio)',
                        lines: 2,
                        helper: 'Satu per baris',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
    );
  }
}
