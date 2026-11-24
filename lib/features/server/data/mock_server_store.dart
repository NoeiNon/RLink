import 'dart:math';

import '../../../core/supabase_config.dart';
import '../models/server.dart';
import '../models/server_content.dart';
import 'supabase_server_store.dart';

/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class ServerException implements Exception {
  const ServerException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Data server contoh yang disimpan di memori saja (hilang saat app di-restart).
///
/// TODO: ganti dengan backend sungguhan. Layar hanya memanggil fungsi-fungsi
/// di sini, jadi cukup mengganti isinya. Penting: aturan seperti "admin tidak
/// boleh join server sendiri" dan "hanya admin boleh menyimpan SOP" harus
/// diperiksa lagi di sisi backend, karena pemeriksaan di tampilan bisa dilewati.
///
/// Token server demo: ETHARIA1
/// Identitas pengguna di data contoh = username (huruf besar/kecil diabaikan).
/// Di backend nanti pakai ID akun.
class MockServerStore {
  MockServerStore._();

  // Tanpa huruf/angka yang mirip (O/0, I/1) supaya token mudah diketik ulang.
  static const String _tokenChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _random = Random.secure();
  static int _counter = 1;
  static int _messageCounter = 1;

  /// Batas per akun, seperti Discord: server yang dibuat dan yang diikuti.
  static const int maxCreated = 3;
  static const int maxJoined = 5;

  static final List<ServerInfo> _servers = [
    const ServerInfo(
      id: 's_0',
      name: 'Etharia Builders',
      token: 'ETHARIA1',
      colorIndex: 0,
      iconIndex: 0,
    ),
  ];

  /// Anggota tiap server: id server -> (username huruf kecil -> peran).
  static final Map<String, Map<String, ServerRole>> _members = {
    's_0': {'admindemo': ServerRole.admin, 'builderdemo': ServerRole.builder},
  };

  static final Map<String, List<ChatMessage>> _messages = {
    's_0': [
      ChatMessage(
        id: 'm_0',
        author: 'AdminDemo',
        isAdmin: true,
        text:
            'Selamat datang di Etharia Builders! Baca SOP di tab Lainnya '
            'sebelum mulai.',
        sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      ChatMessage(
        id: 'm_00',
        author: 'BuilderDemo',
        isAdmin: false,
        text: 'Siap, terima kasih!',
        sentAt: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
    ],
  };

  static final Map<String, SopDocument> _sops = {
    's_0': SopDocument(
      text:
          'SOP Kerja\n\n'
          '1. Ambil project lewat tab Project sebelum mulai bekerja.\n'
          '2. Upload progress secara berkala, jangan menunggu selesai.\n'
          '3. Tekan Mark as Done hanya kalau pekerjaan benar-benar selesai.\n'
          '4. Kalau berhalangan, ajukan Inactive Notice di tab Lainnya.',
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  };

  static Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  static String _key(String username) => username.trim().toLowerCase();

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

  /// Membuat server baru dengan token acak 8 karakter. Pembuatnya tercatat
  /// sebagai admin server itu.
  static Future<ServerInfo> create({
    required String name,
    required String username,
    required int colorIndex,
    required int iconIndex,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.create(
        name: name,
        username: username,
        colorIndex: colorIndex,
        iconIndex: iconIndex,
      );
    }
    await _latency();
    if (_countRole(username, ServerRole.admin) >= maxCreated) {
      throw ServerException(
        'Kamu sudah membuat $maxCreated server (batas maksimum).',
      );
    }
    final server = ServerInfo(
      id: 's_${_counter++}',
      name: name.trim(),
      token: _newToken(),
      colorIndex: colorIndex,
      iconIndex: iconIndex,
    );
    _servers.add(server);
    _members[server.id] = {_key(username): ServerRole.admin};
    _messages[server.id] = [];
    return server;
  }

  /// Bergabung ke server pakai token, sebagai builder. Ditolak kalau token
  /// salah, atau kalau orang ini sudah jadi anggota (termasuk admin) di
  /// server itu, supaya satu orang tidak punya dua peran di satu server.
  static Future<ServerInfo> join({
    required String token,
    required String username,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.join(token: token, username: username);
    }
    await _latency();
    final normalized = token.trim().toUpperCase();

    ServerInfo? server;
    for (final candidate in _servers) {
      if (candidate.token == normalized) {
        server = candidate;
        break;
      }
    }
    if (server == null) {
      throw const ServerException(
        'Token server tidak ditemukan. Cek lagi atau tanya admin servermu.',
      );
    }

    final members = _members.putIfAbsent(server.id, () => {});
    final existing = members[_key(username)];
    if (existing == ServerRole.admin) {
      throw const ServerException('Kamu adalah admin di server ini.');
    }
    if (existing != null) {
      throw const ServerException('Kamu sudah bergabung di server ini.');
    }

    if (_countRole(username, ServerRole.builder) >= maxJoined) {
      throw ServerException(
        'Kamu sudah bergabung di $maxJoined server (batas maksimum). '
        'Tinggalkan salah satu dulu.',
      );
    }

    members[_key(username)] = ServerRole.builder;
    return server;
  }

  // ---- Akun dan keanggotaan ----

  /// Email -> username, supaya akun yang sama dikenali lagi saat login.
  static final Map<String, String> _usernames = {
    'admin@rf.test': 'AdminDemo',
    'builder@rf.test': 'BuilderDemo',
  };

  /// Server yang terakhir dibuka tiap akun (username huruf kecil -> id server).
  static final Map<String, String> _lastServer = {};

  static void rememberUser({required String email, required String username}) {
    _usernames[email.trim().toLowerCase()] = username.trim();
  }

  static String usernameForEmail(String email) {
    final key = email.trim().toLowerCase();
    return _usernames[key] ?? key.split('@').first;
  }

  static int _countRole(String username, ServerRole role) {
    final key = _key(username);
    return _members.values.where((members) => members[key] == role).length;
  }

  /// Semua server yang diikuti akun ini beserta perannya di tiap server.
  static Future<List<ServerMembership>> getMemberships(String username) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.getMemberships(username);
    }
    final key = _key(username);
    final result = <ServerMembership>[];
    for (final server in _servers) {
      final role = _members[server.id]?[key];
      if (role != null) {
        result.add(ServerMembership(server: server, role: role));
      }
    }
    return result;
  }

  /// Daftar anggota satu server (founder dulu). Nama diambil dari akun yang
  /// terdaftar; kalau tidak ketemu, dipakai nama kecilnya.
  /// TODO: backend harus mengembalikan nama dan peran saja, tanpa email.
  static Future<List<ServerMember>> getMembers(String serverId) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.getMembers(serverId);
    }
    await _latency();
    final names = {
      for (final name in _usernames.values) name.toLowerCase(): name,
    };
    final result = [
      for (final entry
          in (_members[serverId] ?? const <String, ServerRole>{}).entries)
        ServerMember(name: names[entry.key] ?? entry.key, role: entry.value),
    ];
    result.sort((a, b) {
      if (a.role != b.role) return a.role == ServerRole.admin ? -1 : 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return result;
  }

  static void setLastServer(String username, String serverId) {
    _lastServer[_key(username)] = serverId;
  }

  static String? lastServerId(String username) => _lastServer[_key(username)];

  /// Keluar dari server. Admin tidak bisa meninggalkan servernya sendiri.
  static Future<void> leave({
    required String serverId,
    required String username,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.leave(serverId: serverId, username: username);
    }
    await _latency();
    final key = _key(username);
    final members = _members[serverId];
    final role = members?[key];

    if (role == null) {
      throw const ServerException('Kamu bukan anggota server ini.');
    }
    if (role == ServerRole.admin) {
      throw const ServerException(
        'Admin tidak bisa meninggalkan servernya sendiri.',
      );
    }

    members!.remove(key);
    if (_lastServer[key] == serverId) _lastServer.remove(key);
  }

  /// Hapus server secara permanen. Hanya boss (admin) server itu yang boleh.
  /// Anggota, obrolan, dan SOP server ikut dihapus.
  static Future<void> deleteServer({
    required String serverId,
    required String username,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.deleteServer(
        serverId: serverId,
        username: username,
      );
    }
    await _latency();
    final role = _members[serverId]?[_key(username)];
    if (role != ServerRole.admin) {
      throw const ServerException(
        'Hanya boss server yang bisa menghapus server ini.',
      );
    }

    _servers.removeWhere((server) => server.id == serverId);
    _members.remove(serverId);
    _messages.remove(serverId);
    _sops.remove(serverId);
    _lastServer.removeWhere((_, id) => id == serverId);
  }

  // ---- Obrolan (Discussion) ----

  static Future<List<ChatMessage>> getMessages(String serverId) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.getMessages(serverId);
    }
    return List<ChatMessage>.of(_messages[serverId] ?? const <ChatMessage>[]);
  }

  static Future<ChatMessage> postMessage({
    required String serverId,
    required String author,
    required bool isAdmin,
    required String text,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.postMessage(
        serverId: serverId,
        author: author,
        isAdmin: isAdmin,
        text: text,
      );
    }
    final message = ChatMessage(
      id: 'm_${_messageCounter++}',
      author: author,
      isAdmin: isAdmin,
      text: text.trim(),
      sentAt: DateTime.now(),
    );
    _messages.putIfAbsent(serverId, () => []).add(message);
    return message;
  }

  // ---- SOP ----

  static Future<SopDocument> getSop(String serverId) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.getSop(serverId);
    }
    await _latency();
    return _sops[serverId] ?? const SopDocument(text: '');
  }

  static Future<SopDocument> saveSop({
    required String serverId,
    required String text,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseServerStore.saveSop(serverId: serverId, text: text);
    }
    await _latency();
    final document = SopDocument(text: text.trim(), updatedAt: DateTime.now());
    _sops[serverId] = document;
    return document;
  }
}
