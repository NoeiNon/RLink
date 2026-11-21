import '../data/mock_server_store.dart' show ServerException;

/// Dilempar saat email belum terdaftar, supaya layar login bisa mengarahkan
/// pengguna ke halaman Daftar.
class AccountNotFoundException extends ServerException {
  const AccountNotFoundException()
      : super('Akun belum terdaftar. Silakan daftar terlebih dahulu.');
}

class WrongPasswordException extends ServerException {
  const WrongPasswordException() : super('Password salah.');
}

class EmailTakenException extends ServerException {
  const EmailTakenException()
      : super('Email ini sudah terdaftar. Silakan masuk.');
}

class UsernameTakenException extends ServerException {
  const UsernameTakenException() : super('Username ini sudah dipakai.');
}
