import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth_exceptions.dart';
import 'mock_server_store.dart' show ServerException;

/// Implementasi autentikasi menggunakan Supabase Auth & PostgreSQL.
class SupabaseAuthStore {
  SupabaseAuthStore._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Daftar akun baru di Supabase Auth.
  static Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final name = username.trim();
    final mail = email.trim().toLowerCase();

    try {
      // Coba periksa apakah username sudah dipakai jika diizinkan
      try {
        final existingUsername = await _client
            .from('profiles')
            .select('id')
            .ilike('username', name)
            .maybeSingle();

        if (existingUsername != null) {
          throw const UsernameTakenException();
        }
      } catch (e) {
        if (e is UsernameTakenException) rethrow;
        // Lanjutkan jika role anon belum diberi hak akses select ke profiles
      }

      final res = await _client.auth.signUp(
        email: mail,
        password: password,
        data: {'username': name},
      );

      if (res.user == null) {
        throw const ServerException('Gagal mendaftar. Silakan coba lagi.');
      }

      // Pastikan baris di tabel profiles terisi jika trigger belum berjalan
      try {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'username': name,
        });
      } catch (_) {}
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') ||
          msg.contains('user already exists') ||
          msg.contains('email address is already in use')) {
        throw const EmailTakenException();
      }
      if (msg.contains('profiles_username_key') ||
          msg.contains('duplicate key value') ||
          msg.contains('username')) {
        throw const UsernameTakenException();
      }
      throw ServerException(e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Masuk dengan email & password, mengembalikan username dari database.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final mail = email.trim().toLowerCase();
      final res = await _client.auth.signInWithPassword(
        email: mail,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw const AccountNotFoundException();
      }

      // Ambil username dari tabel profiles
      try {
        final profile = await _client
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['username'] != null) {
          return profile['username'] as String;
        }
      } catch (_) {}

      final fallback = user.userMetadata?['username'] as String? ??
          mail.split('@').first;
      return fallback;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid credentials')) {
        throw const WrongPasswordException();
      }
      if (msg.contains('user not found') || msg.contains('not found')) {
        throw const AccountNotFoundException();
      }
      if (msg.contains('email not confirmed')) {
        throw const ServerException(
          'Email belum dikonfirmasi. Periksa kotak masuk email Anda atau matikan "Confirm email" di Supabase Dashboard.',
        );
      }
      throw ServerException(e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  /// Keluar dari sesi Supabase.
  static Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }
}
