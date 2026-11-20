import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../data/mock_auth_store.dart';
import '../data/mock_server_store.dart' show ServerException;
import '../widgets/auth_layout.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final username = await MockAuthStore.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      await openStartScreen(context, username);
    } on AccountNotFoundException catch (e) {
      _showError(e.message, action: 'Daftar');
    } on ServerException catch (e) {
      _showError(e.message);
    }
  }

  void _showError(String message, {String? action}) {
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: action == null
              ? null
              : SnackBarAction(label: action, onPressed: _openRegister),
        ),
      );
  }

  void _openRegister() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Selamat datang',
      subtitle: 'Masuk untuk mengelola project builder-mu',
      children: [
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: appInputDecoration(
                  label: 'Email',
                  icon: Icons.mail_outline_rounded,
                ),
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: appInputDecoration(
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: Validators.passwordRequired,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Masuk', loading: _loading, onPressed: _submit),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Belum punya akun?',
              style: TextStyle(color: AppColors.textMuted),
            ),
            TextButton(onPressed: _openRegister, child: const Text('Daftar')),
          ],
        ),
      ],
    );
  }
}
