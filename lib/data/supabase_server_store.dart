import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/server.dart';
import '../models/server_content.dart';
import 'mock_server_store.dart' show ServerException;

/// Implementasi server/workspace menggunakan Supabase Database & Realtime.
class SupabaseServerStore {
  SupabaseServerStore._();

  static SupabaseClient get _client => Supabase.instance.client;

  static const int maxCreated = 3;
  static const int maxJoined = 5;

  static const String _tokenChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final Random _random = Random.secure();
  static final Map<String, String> _lastServerCache = {};

  static String _generateToken() {
    return List<String>.generate(
      8,
      (_) => _tokenChars[_random.nextInt(_tokenChars.length)],
    ).join();
  }

  /// Membuat server baru di database Supabase.
  static Future<ServerInfo> create({
    required String name,
    required String username,
    required int colorIndex,
    required int iconIndex,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ServerException('Sesi masuk berakhir. Silakan login kembali.');
    }

    try {
      // Periksa batas jumlah server yang dibuat (maksimal 3)
      final createdCountRes = await _client
          .from('servers')
          .select('id')
          .eq('created_by', user.id);
      if ((createdCountRes as List).length >= maxCreated) {
        throw ServerException(
          'Kamu sudah membuat $maxCreated server (batas maksimum).',
        );
      }

      final token = _generateToken();
      final insertRes = await _client.from('servers').insert({
        'name': name.trim(),
        'token': token,
        'color_index': colorIndex,
        'icon_index': iconIndex,
        'created_by': user.id,
      }).select().single();

      final serverId = insertRes['id'] as String;

      // Masukkan pembuat sebagai admin server
      await _client.from('server_members').insert({
        'server_id': serverId,
        'user_id': user.id,
        'role': 'admin',
      });

      return ServerInfo(
        id: serverId,
        name: insertRes['name'] as String,
        token: token,
        colorIndex: insertRes['color_index'] as int? ?? colorIndex,
        iconIndex: insertRes['icon_index'] as int? ?? iconIndex,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Gagal membuat server: ${e.toString()}');
    }
  }

  /// Bergabung ke server menggunakan token.
  static Future<ServerInfo> join({
    required String token,
    required String username,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const ServerException('Sesi masuk berakhir. Silakan login kembali.');
    }

    final normalized = token.trim().toUpperCase();

    // 1. Coba lewat RPC join_server_by_token (SECURITY DEFINER)
    try {
      final rpcRes = await _client.rpc(
        'join_server_by_token',
        params: {'token_input': normalized},
      );
      if (rpcRes != null) {
        final sData = rpcRes as Map<String, dynamic>;
        return ServerInfo(
          id: sData['id'] as String,
          name: sData['name'] as String,
          token: sData['token'] as String,
          colorIndex: sData['color_index'] as int? ?? 0,
          iconIndex: sData['icon_index'] as int? ?? 0,
        );
      }
    } catch (rpcErr) {
      final msg = rpcErr.toString();
      if (msg.contains('Token server tidak ditemukan')) {
        throw const ServerException(
          'Token server tidak ditemukan. Cek lagi atau tanya admin servermu.',
        );
      }
      if (msg.contains('admin di server ini')) {
        throw const ServerException('Kamu adalah admin di server ini.');
      }
      if (msg.contains('sudah bergabung')) {
        throw const ServerException('Kamu sudah bergabung di server ini.');
      }
      if (msg.contains('batas maksimum')) {
        throw ServerException(
          'Kamu sudah bergabung di $maxJoined server (batas maksimum). Tinggalkan salah satu dulu.',
        );
      }
    }

    // 2. Fallback query langsung jika RPC belum dieksekusi
    try {
      final serverRes = await _client
          .from('servers')
          .select()
          .eq('token', normalized)
          .maybeSingle();

      if (serverRes == null) {
        throw const ServerException(
          'Token server tidak ditemukan. Cek lagi atau tanya admin servermu.',
        );
      }

      final serverId = serverRes['id'] as String;

      // Cek apakah sudah jadi member
      final memberCheck = await _client
          .from('server_members')
          .select('role')
          .eq('server_id', serverId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberCheck != null) {
        final role = memberCheck['role'] as String;
        if (role == 'admin') {
          throw const ServerException('Kamu adalah admin di server ini.');
        }
        throw const ServerException('Kamu sudah bergabung di server ini.');
      }

      // Cek batas server bergabung (maks 5)
      final joinedRes = await _client
          .from('server_members')
          .select('server_id')
          .eq('user_id', user.id)
          .eq('role', 'builder');
      if ((joinedRes as List).length >= maxJoined) {
        throw ServerException(
          'Kamu sudah bergabung di $maxJoined server (batas maksimum). Tinggalkan salah satu dulu.',
        );
      }

      // Masukkan sebagai builder
      await _client.from('server_members').insert({
        'server_id': serverId,
        'user_id': user.id,
        'role': 'builder',
      });

      return ServerInfo(
        id: serverId,
        name: serverRes['name'] as String,
        token: serverRes['token'] as String,
        colorIndex: serverRes['color_index'] as int? ?? 0,
        iconIndex: serverRes['icon_index'] as int? ?? 0,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Daftar server yang diikuti oleh user beserta perannya.
  static Future<List<ServerMembership>> getMemberships(String username) async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    try {
      final res = await _client
          .from('server_members')
          .select('role, servers(id, name, token, color_index, icon_index)')
          .eq('user_id', user.id);

      final list = <ServerMembership>[];
      for (final row in (res as List)) {
        final sData = row['servers'] as Map<String, dynamic>?;
        if (sData == null) continue;

        final roleStr = row['role'] as String? ?? 'builder';
        final role = roleStr == 'admin' ? ServerRole.admin : ServerRole.builder;

        list.add(
          ServerMembership(
            server: ServerInfo(
              id: sData['id'] as String,
              name: sData['name'] as String? ?? '',
              token: sData['token'] as String? ?? '',
              colorIndex: sData['color_index'] as int? ?? 0,
              iconIndex: sData['icon_index'] as int? ?? 0,
            ),
            role: role,
          ),
        );
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Daftar anggota satu server.
  static Future<List<ServerMember>> getMembers(String serverId) async {
    try {
      final res = await _client
          .from('server_members')
          .select('role, profiles(username)')
          .eq('server_id', serverId);

      final list = <ServerMember>[];
      for (final row in (res as List)) {
        final pData = row['profiles'] as Map<String, dynamic>?;
        final name = pData?['username'] as String? ?? 'Unknown';
        final roleStr = row['role'] as String? ?? 'builder';
        final role = roleStr == 'admin' ? ServerRole.admin : ServerRole.builder;

        list.add(ServerMember(name: name, role: role));
      }

      list.sort((a, b) {
        if (a.role != b.role) return a.role == ServerRole.admin ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Keluar dari server.
  static Future<void> leave({
    required String serverId,
    required String username,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final memberRow = await _client
          .from('server_members')
          .select('role')
          .eq('server_id', serverId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberRow == null) {
        throw const ServerException('Kamu bukan anggota server ini.');
      }

      if (memberRow['role'] == 'admin') {
        throw const ServerException('Admin tidak bisa meninggalkan servernya sendiri.');
      }

      await _client
          .from('server_members')
          .delete()
          .eq('server_id', serverId)
          .eq('user_id', user.id);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Gagal keluar dari server: ${e.toString()}');
    }
  }

  // ---- Obrolan (Discussion) ----

  static Future<List<ChatMessage>> getMessages(String serverId) async {
    try {
      final res = await _client
          .from('server_messages')
          .select()
          .eq('server_id', serverId)
          .order('sent_at', ascending: true);

      return (res as List).map((row) {
        return ChatMessage(
          id: row['id'] as String,
          author: row['author_name'] as String? ?? 'User',
          isAdmin: row['is_admin'] as bool? ?? false,
          text: row['text'] as String? ?? '',
          sentAt: DateTime.tryParse(row['sent_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<ChatMessage> postMessage({
    required String serverId,
    required String author,
    required bool isAdmin,
    required String text,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    try {
      final res = await _client.from('server_messages').insert({
        'server_id': serverId,
        'user_id': user?.id,
        'author_name': author,
        'is_admin': isAdmin,
        'text': text.trim(),
        'sent_at': now.toIso8601String(),
      }).select().single();

      return ChatMessage(
        id: res['id'] as String,
        author: author,
        isAdmin: isAdmin,
        text: text.trim(),
        sentAt: now,
      );
    } catch (e) {
      throw ServerException('Gagal mengirim pesan: ${e.toString()}');
    }
  }

  // ---- SOP ----

  static Future<SopDocument> getSop(String serverId) async {
    try {
      final res = await _client
          .from('server_sops')
          .select()
          .eq('server_id', serverId)
          .maybeSingle();

      if (res == null) return const SopDocument(text: '');

      return SopDocument(
        text: res['text'] as String? ?? '',
        updatedAt: res['updated_at'] != null
            ? DateTime.tryParse(res['updated_at'] as String)
            : null,
      );
    } catch (_) {
      return const SopDocument(text: '');
    }
  }

  static Future<SopDocument> saveSop({
    required String serverId,
    required String text,
  }) async {
    final user = _client.auth.currentUser;
    final now = DateTime.now();

    try {
      await _client.from('server_sops').upsert({
        'server_id': serverId,
        'text': text.trim(),
        'updated_at': now.toIso8601String(),
        'updated_by': user?.id,
      });

      return SopDocument(text: text.trim(), updatedAt: now);
    } catch (e) {
      throw ServerException('Gagal menyimpan SOP: ${e.toString()}');
    }
  }

  // ---- Cache Server Terakhir ----

  static void setLastServer(String username, String serverId) {
    _lastServerCache[username.toLowerCase()] = serverId;
  }

  static String? lastServerId(String username) {
    return _lastServerCache[username.toLowerCase()];
  }
}
