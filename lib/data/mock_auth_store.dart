import 'mock_server_store.dart' show ServerException;

/// Dilempar saat email belum terdaftar, supaya layar login bisa mengarahkan
/// pengguna ke halaman Daftar.
class AccountNotFoundException extends ServerException {
  const AccountNotFoundException()
      : super('Akun belum terdaftar. Daftar dulu untuk membuat username.');
}

class _Account {
  const _Account({required this.username, required this.password});

  final String username;
  final String password;
}

/// Akun contoh di memori (hilang saat app di-restart).
///
/// TODO: ganti dengan backend auth sungguhan. Di backend, password WAJIB
/// disimpan sebagai hash (bcrypt/argon2), bukan teks biasa, dan pembatasan
/// percobaan login serta pemeriksaan email/username unik harus dilakukan di
/// server, karena pemeriksaan di aplikasi bisa dilewati.
///
/// Akun demo: admin@rf.test / admin123 dan builder@rf.test / builder123.
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

  /// Daftar akun baru. Email dan username harus belum dipakai.
  static Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    await _latency();
    final key = _email(email);
    final name = username.trim();

    if (_accounts.containsKey(key)) {
      throw const ServerException('Email ini sudah terdaftar. Silakan masuk.');
    }
    final taken = _accounts.values
        .any((a) => a.username.toLowerCase() == name.toLowerCase());
    if (taken) {
      throw const ServerException('Username ini sudah dipakai.');
    }
    _accounts[key] = _Account(username: name, password: password);
  }

  /// Masuk. Mengembalikan username akun. Akun yang belum terdaftar ditolak.
  static Future<String> login({
    required String email,
    required String password,
  }) async {
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
      throw const ServerException('Password salah.');
    }

    _failures.remove(key);
    _lockedUntil.remove(key);
    return account.username;
  }
}
