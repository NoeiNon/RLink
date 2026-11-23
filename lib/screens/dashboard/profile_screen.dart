import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;

/// Profil pengguna. Pengaturan akun dan pembuat CV menyusul.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final initial = username.isEmpty ? '?' : username[0].toUpperCase();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kFieldBorder),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CV',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Buat CV-mu di sini, lalu publikasikan supaya '
                          'perusahaan dan tim bisa menemukan dan memilihmu '
                          'sebagai kandidat.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Publikasikan CV',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                            Switch(value: false, onChanged: null),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Segera hadir',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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
