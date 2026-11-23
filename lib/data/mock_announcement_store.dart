/// Pengumuman server. SEMENTARA tersimpan di memori (hilang saat app
/// ditutup). Nanti diganti tabel Supabase seperti pesan dan SOP.
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

class MockAnnouncementStore {
  static final Map<String, List<Announcement>> _items = {};

  /// Terbaru di atas.
  static List<Announcement> list(String serverId) =>
      List.unmodifiable(_items[serverId] ?? const <Announcement>[]);

  static Announcement post({
    required String serverId,
    required String title,
    required String text,
    required String author,
  }) {
    final item = Announcement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      text: text.trim(),
      author: author,
      createdAt: DateTime.now(),
    );
    _items[serverId] = [item, ...?_items[serverId]];
    return item;
  }

  static void delete(String serverId, String id) {
    _items[serverId]?.removeWhere((a) => a.id == id);
  }
}
