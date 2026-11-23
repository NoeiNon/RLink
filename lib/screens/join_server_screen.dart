import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../data/mock_server_store.dart';
import '../models/server.dart';
import '../widgets/auth_split_layout.dart'
    show CompactButton, compactInputDecoration;
import '../widgets/compact_card_page.dart';
import 'server/server_home_screen.dart';

/// Gabung server: tempel token dari admin, lalu konfirmasi.
/// Yang bergabung otomatis jadi Builder.
class JoinServerScreen extends StatefulWidget {
  const JoinServerScreen({super.key, required this.username});

  final String username;

  @override
  State<JoinServerScreen> createState() => _JoinServerScreenState();
}

class _JoinServerScreenState extends State<JoinServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final server = await MockServerStore.join(
        token: _tokenController.text,
        username: widget.username,
      );
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ServerHomeScreen(
            username: widget.username,
            server: server,
            role: ServerRole.builder,
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
        _error = 'Terjadi kesalahan. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('Gabung server'),
      ),
      body: CompactCardPage(
        children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0x33B69CFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vpn_key_outlined,
                size: 28,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Masukkan token server',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Minta token ke boss servermu, lalu tempel di bawah. '
            'Kamu akan bergabung sebagai Builder.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _tokenController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 13.5),
              decoration: compactInputDecoration(
                label: 'Token server',
                icon: Icons.vpn_key_outlined,
              ).copyWith(errorText: _error),
              validator: Validators.token,
            ),
          ),
          const SizedBox(height: 16),
          CompactButton(
            label: 'Konfirmasi',
            loading: _loading,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          const Text(
            'Mode demo: coba token ETHARIA1',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
