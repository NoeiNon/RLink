export '../../core/auth_exceptions.dart';
import '../../core/auth_exceptions.dart';
import '../../core/supabase_config.dart';
import '../server/data/mock_server_store.dart' show ServerException;
import 'supabase_auth_store.dart';

class _Account {
  const _Account({required this.username, required this.password});

  final String username;
  final String password;
}

/// Akun contoh di memori atau beralih ke Supabase saat konfigurasi tersedia.
class MockAuthStore {
  MockAuthStore._();

  static const int _maxFailures = 5;
  static const Duration _lockDuration = Duration(seconds: 30);

  /// email (huruf kecil) -> akun.
  static final Map<String, _Account> _accounts = {
    'admin@rf.test':
        const _Account(username: 'AdminDemo', password: 'admin123'),
    'builder@rf.test':
        const _Account(username: 'BuilderDemo', password: 'builder123'),
  };

  static final Map<String, int> _failures = {};
  static final Map<String, DateTime> _lockedUntil = {};

  static String _email(String value) => value.trim().toLowerCase();

  static Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 500));

  /// Daftar akun baru.
  static Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseAuthStore.register(
        email: email,
        username: username,
        password: password,
      );
    }

    await _latency();
    final key = _email(email);
    final name = username.trim();

    if (_accounts.containsKey(key)) {
      throw const EmailTakenException();
    }
    final taken = _accounts.values
        .any((a) => a.username.toLowerCase() == name.toLowerCase());
    if (taken) {
      throw const UsernameTakenException();
    }
    _accounts[key] = _Account(username: name, password: password);
  }

  /// Masuk. Mengembalikan username akun.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabaseAuthStore.login(
        email: email,
        password: password,
      );
    }

    await _latency();
    final key = _email(email);

    final lockedUntil = _lockedUntil[key];
    if (lockedUntil != null && lockedUntil.isAfter(DateTime.now())) {
      final seconds = lockedUntil.difference(DateTime.now()).inSeconds + 1;
      throw ServerException(
        'Terlalu banyak percobaan. Coba lagi dalam $seconds detik.',
      );
    }

    final account = _accounts[key];
    if (account == null) throw const AccountNotFoundException();

    if (account.password != password) {
      final count = (_failures[key] ?? 0) + 1;
      if (count >= _maxFailures) {
        _failures.remove(key);
        _lockedUntil[key] = DateTime.now().add(_lockDuration);
        throw const ServerException(
          'Terlalu banyak percobaan. Coba lagi dalam 30 detik.',
        );
      }
      _failures[key] = count;
      throw const WrongPasswordException();
    }

    _failures.remove(key);
    _lockedUntil.remove(key);
    return account.username;
  }
}
