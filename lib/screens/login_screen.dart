import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/session_manager.dart';
import '../core/validators.dart';
import '../data/mock_auth_store.dart';
import '../data/mock_server_store.dart' show ServerException;
import '../widgets/app_feedback.dart';
import '../widgets/auth_split_layout.dart';
import 'app_router.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    try {
      final username = await MockAuthStore.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await SessionManager.recordActivity(username);
      if (!mounted) return;
      await openStartScreen(context, username);
    } on AccountNotFoundException catch (e) {
      _fail(email: e.message);
    } on WrongPasswordException catch (e) {
      _fail(password: e.message);
    } on ServerException catch (e) {
      _fail(general: e.message);
    }
  }

  void _fail({String? email, String? password, String? general}) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _emailError = email;
      _passwordError = password;
      _generalError = general;
    });
  }

  void _clearErrors() {
    if (_emailError == null &&
        _passwordError == null &&
        _generalError == null) {
      return;
    }
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthSplitLayout(
      title: 'Selamat datang',
      subtitle: 'Masuk untuk cari kerja, jualan, dan bangun tim.',
      footer: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Belum punya akun? ',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
          GestureDetector(
            onTap: _openRegister,
            child: const Text(
              'Daftar',
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
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                style: const TextStyle(fontSize: 13.5),
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) => _clearErrors(),
                decoration:
                    compactInputDecoration(
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        tooltip: _obscure
                            ? 'Tampilkan password'
                            : 'Sembunyikan',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ).copyWith(
                      errorText: _passwordError,
                      errorStyle: kFieldErrorStyle,
                    ),
                validator: Validators.passwordRequired,
              ),
            ],
          ),
        ),
        if (_generalError != null) ...[
          const SizedBox(height: 12),
          InlineError(_generalError!),
        ],
        const SizedBox(height: 20),
        CompactButton(label: 'Masuk', loading: _loading, onPressed: _submit),
      ],
    );
  }
}
