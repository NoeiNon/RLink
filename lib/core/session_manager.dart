import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/supabase_auth_store.dart';
import 'supabase_config.dart';

/// Pengelola sesi login dengan batas tidak aktif (AFK) 7 hari (rolling window).
class SessionManager {
  SessionManager._();

  static const String _keyLastActive = 'session_last_active_timestamp';
  static const String _keyUsername = 'session_saved_username';

  /// Batas maksimal AFK: 7 hari.
  static const Duration maxInactivity = Duration(days: 7);

  /// Catat aktivitas user saat ini (mereset batas AFK 7 hari ke depan).
  static Future<void> recordActivity([String? username]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
      if (username != null && username.isNotEmpty) {
        await prefs.setString(_keyUsername, username);
      }
    } catch (e) {
      debugPrint('SessionManager recordActivity error: $e');
    }
  }

  /// Hapus riwayat session saat logout manual atau saat sesi kedaluwarsa.
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastActive);
      await prefs.remove(_keyUsername);
      if (SupabaseConfig.isConfigured) {
        await SupabaseAuthStore.logout();
      }
    } catch (e) {
      debugPrint('SessionManager clearSession error: $e');
    }
  }

  /// Cek status sesi login:
  /// - Mengembalikan `username` jika sesi login aktif dan belum lewat batas AFK 7 hari.
  /// - Mengembalikan `null` jika belum login atau sudah AFK lebih dari 7 hari.
  static Future<String?> checkSession() async {
    if (!SupabaseConfig.isConfigured) return null;

    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      final user = client.auth.currentUser;

      if (session == null || user == null) {
        await clearSession();
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final lastActiveMillis = prefs.getInt(_keyLastActive);

      if (lastActiveMillis != null) {
        final lastActive =
            DateTime.fromMillisecondsSinceEpoch(lastActiveMillis);
        final elapsed = DateTime.now().difference(lastActive);

        // Jika AFK melebihi 7 hari:
        if (elapsed > maxInactivity) {
          debugPrint('Sesi kedaluwarsa karena tidak aktif lebih dari 7 hari.');
          await clearSession();
          return null;
        }
      }

      // Sesi masih aktif dalam 7 hari -> perbarui timestamp agar batas 7 hari bergeser
      await recordActivity();

      // Ambil username yang tersimpan
      final savedUsername = prefs.getString(_keyUsername);
      if (savedUsername != null && savedUsername.isNotEmpty) {
        return savedUsername;
      }

      // Fallback: ambil username dari tabel profiles
      try {
        final profile = await client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['username'] != null) {
          final uname = profile['username'] as String;
          await prefs.setString(_keyUsername, uname);
          return uname;
        }
      } catch (_) {}

      final fallback = user.userMetadata?['username'] as String? ??
          user.email?.split('@').first ??
          'User';
      await prefs.setString(_keyUsername, fallback);
      return fallback;
    } catch (e) {
      debugPrint('SessionManager checkSession error: $e');
      return null;
    }
  }
}
