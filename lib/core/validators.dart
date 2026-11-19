/// Validasi isian form. Semua pesan error memakai Bahasa Indonesia.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _usernameRegex = RegExp(r'^[A-Za-z0-9_.]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email wajib diisi';
    if (!_emailRegex.hasMatch(text)) return 'Format email tidak valid';
    return null;
  }

  /// Untuk halaman login: cukup tidak boleh kosong.
  static String? passwordRequired(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    return null;
  }

  /// Untuk halaman daftar: minimal 6 karakter.
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Password wajib diisi';
    if (text.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Username wajib diisi';
    if (text.length < 3 || text.length > 20) {
      return 'Username 3 sampai 20 karakter';
    }
    if (!_usernameRegex.hasMatch(text)) {
      return 'Hanya huruf, angka, titik, dan underscore';
    }
    return null;
  }

  static String? serverName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Nama server wajib diisi';
    if (text.length < 3 || text.length > 30) {
      return 'Nama server 3 sampai 30 karakter';
    }
    return null;
  }

  static String? token(String? value) {
    if (value == null || value.trim().isEmpty) return 'Token wajib diisi';
    return null;
  }
}
