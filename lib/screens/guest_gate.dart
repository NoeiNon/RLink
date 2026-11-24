import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Pengunjung belum login boleh melihat-lihat. Begitu menekan aksi yang
/// butuh akun, tampilkan ajakan masuk lewat fungsi-fungsi di bawah ini.

void openLoginFromGuest(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen(allowBack: true)),
  );
}

/// Daftar dibuka di atas Masuk, jadi tombol "Masuk" di halaman daftar dan
/// tombol kembali di halaman masuk membawa pengunjung ke jalur yang benar.
void openRegisterFromGuest(BuildContext context) {
  final navigator = Navigator.of(context);
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen(allowBack: true)),
  );
  navigator.push(
    MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
  );
}

/// Dialog "Masuk dulu" untuk aksi yang butuh akun.
Future<void> promptLogin(BuildContext context, {String? message}) async {
  final ok = await showConfirmDialog(
    context,
    icon: Icons.lock_outline_rounded,
    color: AppColors.primary,
    title: 'Masuk dulu',
    message: message ?? 'Masuk atau daftar akun untuk melanjutkan.',
    confirmLabel: 'Masuk',
    cancelLabel: 'Nanti',
  );
  if (ok == true && context.mounted) openLoginFromGuest(context);
}

/// Kotak ajakan masuk, dipakai di tempat yang isinya butuh akun.
class GuestPrompt extends StatelessWidget {
  const GuestPrompt({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.lock_outline_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0x335865F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => openLoginFromGuest(context),
                child: const Text('Masuk'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => openRegisterFromGuest(context),
                child: const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
