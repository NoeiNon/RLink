import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/validators.dart';
import '../widgets/auth_layout.dart';
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

    setState(() => _loading = true);

    // TODO: ganti dengan pendaftaran sungguhan setelah backend dipilih.
    // Sekarang hanya simulasi: akun tidak benar-benar tersimpan.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // Hapus halaman Daftar dan Login dari riwayat, jadi tombol kembali
    // tidak membawa pengguna ke halaman login lagi.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => HomeScreen(username: _usernameController.text.trim()),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Buat akun',
      subtitle: 'Setelah daftar, kamu bisa buat server atau gabung server',
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
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                decoration: appInputDecoration(
                  label: 'Username',
                  helper: 'Bebas: nama Minecraft atau nama buatanmu sendiri',
                  icon: Icons.person_outline_rounded,
                ),
                validator: Validators.username,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                decoration: appInputDecoration(
                  label: 'Password',
                  helper: 'Minimal 6 karakter',
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
                validator: Validators.newPassword,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: appInputDecoration(
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
        const SizedBox(height: 24),
        PrimaryButton(label: 'Daftar', loading: _loading, onPressed: _submit),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sudah punya akun?',
              style: TextStyle(color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Masuk'),
            ),
          ],
        ),
      ],
    );
  }
}
