import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/session_manager.dart';
import '../core/validators.dart';
import '../data/mock_auth_store.dart';
import '../data/mock_server_store.dart' show ServerException;
import '../widgets/app_feedback.dart';
import '../widgets/auth_split_layout.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _usernameError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _emailError = null;
      _usernameError = null;
      _generalError = null;
    });

    try {
      await MockAuthStore.register(
        email: _emailController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );
    } on EmailTakenException catch (e) {
      _fail(email: e.message);
      return;
    } on UsernameTakenException catch (e) {
      _fail(username: e.message);
      return;
    } on ServerException catch (e) {
      _fail(general: e.message);
      return;
    }
    if (!mounted) return;

    final uname = _usernameController.text.trim();
    await SessionManager.recordActivity(uname);

    // Hapus halaman Daftar dan Login dari riwayat, jadi tombol kembali
    // tidak membawa pengguna ke halaman login lagi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => HomeScreen(username: uname)),
      (route) => false,
    );
  }

  void _fail({String? email, String? username, String? general}) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _emailError = email;
      _usernameError = username;
      _generalError = general;
    });
  }

  void _clearErrors() {
    if (_emailError == null &&
        _usernameError == null &&
        _generalError == null) {
      return;
    }
    setState(() {
      _emailError = null;
      _usernameError = null;
      _generalError = null;
    });
  }

  Widget _eyeButton() => IconButton(
    iconSize: 16,
    padding: EdgeInsets.zero,
    tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan',
    icon: Icon(
      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
    ),
    onPressed: () => setState(() => _obscure = !_obscure),
  );

  @override
  Widget build(BuildContext context) {
    return AuthSplitLayout(
      title: 'Daftar ke RLink',
      subtitle: 'Gabung untuk cari kerja, jualan, dan bangun tim.',
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sudah punya akun? ',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text(
              'Masuk',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13.5),
                onChanged: (_) => _clearErrors(),
                decoration:
                    compactInputDecoration(
                      label: 'Email',
                      icon: Icons.mail_outline_rounded,
                    ).copyWith(
                      errorText: _emailError,
                      errorStyle: kFieldErrorStyle,
                      errorMaxLines: 2,
                    ),
                validator: Validators.email,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13.5),
                onChanged: (_) => _clearErrors(),
                decoration:
                    compactInputDecoration(
                      label: 'Username',
                      helper: 'Buat Username unikmu.',
                      icon: Icons.person_outline_rounded,
                    ).copyWith(
                      errorText: _usernameError,
                      errorStyle: kFieldErrorStyle,
                      errorMaxLines: 2,
                    ),
                validator: Validators.username,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                style: const TextStyle(fontSize: 13.5),
                decoration: compactInputDecoration(
                  label: 'Password',
                  helper: 'Minimal 6 karakter',
                  icon: Icons.lock_outline_rounded,
                  suffix: _eyeButton(),
                ),
                validator: Validators.newPassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 13.5),
                onFieldSubmitted: (_) => _submit(),
                decoration: compactInputDecoration(
                  label: 'Ulangi password',
                  icon: Icons.lock_outline_rounded,
                ),
                validator: (value) => value != _passwordController.text
                    ? 'Password tidak sama'
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_generalError != null) ...[
          InlineError(_generalError!),
          const SizedBox(height: 12),
        ],
        CompactButton(label: 'Daftar', loading: _loading, onPressed: _submit),
      ],
    );
  }
}
