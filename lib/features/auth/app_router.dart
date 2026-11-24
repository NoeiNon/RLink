import 'package:flutter/material.dart';

import '../../core/session_manager.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

/// Logout: hapus sesi dulu (tunggu sampai selesai), baru pindah ke Login dan
/// kosongkan seluruh riwayat halaman. Dipakai semua tombol logout supaya
/// tidak ada yang lupa menghapus sesi, dan tombol kembali tidak bisa
/// membawa pengguna ke halaman lama.
Future<void> logoutToLogin(BuildContext context) async {
  final navigator = Navigator.of(context);
  await SessionManager.clearSession();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    (route) => false,
  );
}

/// Membuka beranda utama (dashboard) dan mengosongkan riwayat halaman.
/// Dari sini pengguna membuka server, buat server baru, atau gabung server.
Future<void> openStartScreen(BuildContext context, String username) async {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => DashboardScreen(username: username),
    ),
    (route) => false,
  );
}
