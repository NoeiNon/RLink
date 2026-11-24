import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../models/cv.dart';

/// Penyimpanan CV pengguna. Mode demo: di memori. Mode Supabase: tabel
/// `user_cvs` (lihat supabase/cv.sql) yang hanya bisa dibaca pemiliknya.
class CvStore {
  static final Map<String, CvData> _mock = {};

  static SupabaseClient get _client => Supabase.instance.client;

  /// null = belum pernah mengisi CV.
  static Future<CvData?> load(String username) async {
    if (SupabaseConfig.isConfigured) {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;
      final row = await _client
          .from('user_cvs')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (row == null) return null;
      return CvData.fromJson(
        Map<String, dynamic>.from(row['data'] as Map),
        updatedAt: DateTime.tryParse(
          row['updated_at'] as String? ?? '',
        )?.toLocal(),
      );
    }
    return _mock[username];
  }

  static Future<void> save(String username, CvData cv) async {
    if (SupabaseConfig.isConfigured) {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw Exception('Kamu belum login.');
      await _client.from('user_cvs').upsert({
        'user_id': uid,
        'data': cv.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      return;
    }
    _mock[username] = CvData.fromJson(cv.toJson(), updatedAt: DateTime.now());
  }
}
