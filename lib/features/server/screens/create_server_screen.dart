import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../core/validators.dart';
import '../data/mock_server_store.dart';
import '../models/server.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/auth_layout.dart' show kFieldBorder;
import '../../../widgets/auth_split_layout.dart'
    show CompactButton, compactInputDecoration;
import '../../../widgets/compact_card_page.dart';
import '../widgets/server_avatar.dart';
import 'server_home_screen.dart';

/// Buat server baru: cukup nama dan profil (warna + ikon).
/// Pembuatnya otomatis jadi admin, token undangan dibuat otomatis.
class CreateServerScreen extends StatefulWidget {
  const CreateServerScreen({super.key, required this.username});

  final String username;

  @override
  State<CreateServerScreen> createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends State<CreateServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _colorIndex = 0;
  int _iconIndex = 0;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final server = await MockServerStore.create(
        name: _nameController.text,
        username: widget.username,
        colorIndex: _colorIndex,
        iconIndex: _iconIndex,
      );
      if (!mounted) return;

      // Kosongkan riwayat halaman, jadi tombol kembali tidak membawa
      // pengguna ke halaman "belum punya server" lagi.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ServerHomeScreen(
            username: widget.username,
            server: server,
            role: ServerRole.admin,
          ),
        ),
        (route) => false,
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal membuat server. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CompactCardPage(
        title: 'Buat server',
        children: [
          Center(
            child: ServerAvatar(
              colorIndex: _colorIndex,
              iconIndex: _iconIndex,
              size: 64,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Atur tampilan servermu',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 13.5),
              decoration: compactInputDecoration(
                label: 'Nama server',
                icon: Icons.dns_outlined,
              ),
              validator: Validators.serverName,
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Warna'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < kServerColors.length; i++) _colorSwatch(i),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Ikon'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < kServerIcons.length; i++) _iconOption(i),
            ],
          ),
          const SizedBox(height: 18),
          const _InfoNote(
            'Kamu otomatis jadi boss di server ini. Token undangan dibuat '
            'otomatis dan bisa disalin dari halaman server.',
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            InlineError(_error!),
          ],
          const SizedBox(height: 16),
          CompactButton(
            label: 'Buat server',
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _colorSwatch(int index) {
    final selected = index == _colorIndex;

    return GestureDetector(
      onTap: () => setState(() => _colorIndex = index),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: kServerColors[index],
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
            : null,
      ),
    );
  }

  Widget _iconOption(int index) {
    final selected = index == _iconIndex;

    return GestureDetector(
      onTap: () => setState(() => _iconIndex = index),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: selected ? const Color(0x335865F2) : AppColors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primary : kFieldBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Icon(
          kServerIcons[index],
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
