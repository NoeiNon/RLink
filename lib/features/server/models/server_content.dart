/// Satu pesan di obrolan (Discussion) sebuah server.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.author,
    required this.isAdmin,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final String author;

  /// Peran pengirim di server ini, untuk lencana di samping nama.
  final bool isAdmin;
  final String text;
  final DateTime sentAt;
}

/// Isi SOP sebuah server: satu teks panjang, hanya admin yang bisa mengubah.
class SopDocument {
  const SopDocument({required this.text, this.updatedAt});

  final String text;
  final DateTime? updatedAt;
}
