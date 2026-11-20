/// Peran seseorang di satu server. Peran melekat ke server, bukan ke akun:
/// pembuat server jadi admin di servernya sendiri, dan jadi builder kalau
/// bergabung di server orang lain.
enum ServerRole { admin, builder }

/// Data satu server.
class ServerInfo {
  const ServerInfo({
    required this.id,
    required this.name,
    required this.token,
    required this.colorIndex,
    required this.iconIndex,
  });

  final String id;
  final String name;

  /// Token undangan. Di tampilan, hanya admin yang boleh melihatnya.
  /// Saat tersambung ke backend, pastikan builder juga tidak bisa
  /// mengambil token ini dari server.
  final String token;

  /// Profil server: pilihan warna dan ikon (indeks ke daftar di
  /// `widgets/server_avatar.dart`). Foto bisa menyusul saat backend ada.
  final int colorIndex;
  final int iconIndex;
}

/// Keanggotaan satu akun di satu server: servernya dan peran akun itu di sana.
class ServerMembership {
  const ServerMembership({required this.server, required this.role});

  final ServerInfo server;
  final ServerRole role;
}

/// Satu anggota server: nama tampilan dan perannya.
class ServerMember {
  const ServerMember({required this.name, required this.role});

  final String name;
  final ServerRole role;
}
