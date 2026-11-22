import 'package:flutter/material.dart';

import '../core/session_manager.dart';
import '../data/mock_server_store.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'server/server_home_screen.dart';

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

/// Membuka layar awal yang sesuai untuk akun ini dan mengosongkan riwayat
/// halaman: server yang terakhir dibuka (atau server pertama), atau halaman
/// "belum punya server" kalau akun belum punya server sama sekali.
Future<void> openStartScreen(BuildContext context, String username) async {
  final memberships = await MockServerStore.getMemberships(username);
  if (!context.mounted) return;

  final Widget screen;
  if (memberships.isEmpty) {
    screen = HomeScreen(username: username);
  } else {
    final lastId = MockServerStore.lastServerId(username);
    final target = memberships.firstWhere(
      (membership) => membership.server.id == lastId,
      orElse: () => memberships.first,
    );
    screen = ServerHomeScreen(
      username: username,
      server: target.server,
      role: target.role,
    );
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => screen),
    (route) => false,
  );
}
