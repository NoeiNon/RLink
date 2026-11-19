import 'dart:math';

import '../models/server.dart';

/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class ServerException implements Exception {
  const ServerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Data server contoh yang disimpan di memori saja (hilang saat app di-restart).
///
/// TODO: ganti dengan backend sungguhan. Layar hanya memanggil `create` dan
/// `findByToken`, jadi cukup mengganti isi dua fungsi ini.
///
/// Token server demo: ETHARIA1
class MockServerStore {
  MockServerStore._();

  // Tanpa huruf/angka yang mirip (O/0, I/1) supaya token mudah diketik ulang.
  static const String _tokenChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _random = Random.secure();
  static int _counter = 1;

  static final List<ServerInfo> _servers = [
    const ServerInfo(
      id: 's_0',
      name: 'Etharia Builders',
      token: 'ETHARIA1',
      colorIndex: 0,
      iconIndex: 0,
    ),
  ];

  static Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  static String _newToken() {
    while (true) {
      final candidate = List<String>.generate(
        8,
        (_) => _tokenChars[_random.nextInt(_tokenChars.length)],
      ).join();
      final taken = _servers.any((server) => server.token == candidate);
      if (!taken) return candidate;
    }
  }

  /// Membuat server baru dengan token acak 8 karakter.
  static Future<ServerInfo> create({
    required String name,
    required int colorIndex,
    required int iconIndex,
  }) async {
    await _latency();
    final server = ServerInfo(
      id: 's_${_counter++}',
      name: name.trim(),
      token: _newToken(),
      colorIndex: colorIndex,
      iconIndex: iconIndex,
    );
    _servers.add(server);
    return server;
  }

  /// Mencari server dari token. Huruf besar/kecil tidak dibedakan.
  static Future<ServerInfo> findByToken(String token) async {
    await _latency();
    final normalized = token.trim().toUpperCase();
    for (final server in _servers) {
      if (server.token == normalized) return server;
    }
    throw const ServerException(
      'Token server tidak ditemukan. Cek lagi atau tanya admin servermu.',
    );
  }
}
