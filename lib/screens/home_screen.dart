import 'package:flutter/material.dart';

import '../core/app_constants.dart';
import '../core/app_theme.dart';
import '../widgets/auth_layout.dart';
import 'app_router.dart';
import 'create_server_screen.dart';
import 'join_server_screen.dart';

/// Halaman depan untuk akun yang belum punya server (seperti Discord saat
/// baru daftar). Dua pilihan: buat server sendiri (jadi admin) atau gabung
/// server orang lain pakai token.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.username});

  final String username;

  void _logout(BuildContext context) => logoutToLogin(context);

  void _openCreateServer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreateServerScreen(username: username),
      ),
    );
  }

  void _openJoinServer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JoinServerScreen(username: username),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar akun',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppLogo(width: 110)),
                  const SizedBox(height: 8),
                  Text(
                    'Halo, $username!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kamu belum bergabung di server mana pun.\n'
                    'Mulai dengan salah satu pilihan di bawah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _ActionCard(
                    icon: Icons.add_rounded,
                    iconBackground: const Color(0x335865F2),
                    title: 'Buat server',
                    description:
                        'Mulai server sendiri. Kamu jadi boss dan dapat '
                        'token untuk mengundang builder.',
                    onTap: () => _openCreateServer(context),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.vpn_key_outlined,
                    iconBackground: const Color(0x33B69CFF),
                    title: 'Gabung server',
                    description:
                        'Punya token dari boss? Masukkan di sini untuk '
                        'bergabung sebagai builder.',
                    onTap: () => _openJoinServer(context),
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

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kFieldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.textPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
