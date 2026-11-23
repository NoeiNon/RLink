import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import 'mock_server_store.dart' show ServerException;

/// Pengumuman dari boss untuk seluruh anggota server.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.text,
    required this.author,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String text;
  final String author;
  final DateTime createdAt;
}

/// Mode demo: tersimpan di memori. Mode Supabase: tabel
/// `server_announcements` (lihat supabase/announcements.sql).
class MockAnnouncementStore {
  static final Map<String, List<Announcement>> _items = {};

  static SupabaseClient get _client => Supabase.instance.client;

  /// Terbaru di atas.
  static Future<List<Announcement>> list(String serverId) async {
    if (SupabaseConfig.isConfigured) {
      try {
        final res = await _client
            .from('server_announcements')
            .select()
            .eq('server_id', serverId)
            .order('created_at', ascending: false);
        return (res as List).map((row) {
          return Announcement(
            id: row['id'] as String,
            title: row['title'] as String? ?? '',
            text: row['text'] as String? ?? '',
            author: row['author_name'] as String? ?? 'Boss',
            createdAt:
                DateTime.tryParse(row['created_at'] as String? ?? '')
                    ?.toLocal() ??
                DateTime.now(),
          );
        }).toList();
      } catch (_) {
        return const [];
      }
    }
    return List.unmodifiable(_items[serverId] ?? const <Announcement>[]);
  }

  static Future<void> post({
    required String serverId,
    required String title,
    required String text,
    required String author,
  }) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _client.from('server_announcements').insert({
          'server_id': serverId,
          'user_id': _client.auth.currentUser?.id,
          'author_name': author,
          'title': title.trim(),
          'text': text.trim(),
        });
      } catch (e) {
        throw ServerException('Gagal memposting pengumuman: $e');
      }
      return;
    }
    final item = Announcement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      text: text.trim(),
      author: author,
      createdAt: DateTime.now(),
    );
    _items[serverId] = [item, ...?_items[serverId]];
  }

  static Future<void> delete(String serverId, String id) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await _client.from('server_announcements').delete().eq('id', id);
      } catch (e) {
        throw ServerException('Gagal menghapus pengumuman: $e');
      }
      return;
    }
    _items[serverId]?.removeWhere((a) => a.id == id);
  }
}
