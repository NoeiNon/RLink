import '../models/project.dart';
import 'mock_server_store.dart' show ServerException;

/// Data project contoh, disimpan di memori (hilang saat app di-restart).
/// Hanya server demo (s_0) yang berisi project; server baru masih kosong
/// sampai admin bisa membuat project (tahap berikutnya).
///
/// TODO: ganti dengan backend. Aturan di sini (siapa boleh claim, slot penuh,
/// hanya worker yang boleh kirim update) harus diperiksa lagi di backend.
/// TODO: tolak claim kalau status builder sedang libur (Inactive Notice).
class MockProjectStore {
  MockProjectStore._();

  static final Map<String, List<Project>> _byServer = {'s_0': _seed()};

  static List<Project> _seed() {
    final now = DateTime.now();
    return [
      Project(
        id: 'p_1',
        title: 'DV. Builder - Butcher Village',
        from: 'Your Majesty',
        payment: 'Sekitar \$21.000',
        detail: 'Lokasi: X 4256 | Y 114 | Z 988.\n'
            'Blueprint: intinya sebuah desa seperti Oliver.',
        deadline: '3 minggu',
        maxWorkers: 3,
        author: 'AdminDemo',
        createdAt: now.subtract(const Duration(days: 2)),
        tags: const ['Urgent'],
      ),
      Project(
        id: 'p_2',
        title: 'DV. Resource - Pembersihan Sisa Build',
        from: 'Mandor',
        payment: '\$2.500',
        detail: 'Banyak chest yang terlantar setelah selesai ngebuild belum '
            'dibersihkan. Dan juga fence-fence yang disekitar belum '
            'dibersihkan.',
        deadline: '5 hari',
        maxWorkers: 3,
        author: 'AdminDemo',
        createdAt: now.subtract(const Duration(days: 4)),
        status: ProjectStatus.onProgress,
        workers: const ['BuilderDemo'],
        updates: [
          ProjectUpdate(
            author: 'BuilderDemo',
            text: 'Mulai bersihin chest di area utara.',
            sentAt: now.subtract(const Duration(hours: 3)),
          ),
          ProjectUpdate(
            author: 'BuilderDemo',
            text: 'Area utara beres, lanjut ke fence sisi timur.',
            sentAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      Project(
        id: 'p_3',
        title: 'Duke - Tempat Mining',
        from: 'Duke',
        payment: '\$1.200',
        detail: 'Rapikan area tambang dan pasang penerangan di semua lorong.',
        deadline: '1 minggu',
        maxWorkers: 2,
        author: 'AdminDemo',
        createdAt: now.subtract(const Duration(days: 12)),
        status: ProjectStatus.finished,
        workers: const ['BuilderDemo'],
      ),
    ];
  }

  static Future<void> _latency() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  static Future<List<Project>> list(String serverId) async {
    await _latency();
    return List<Project>.of(_byServer[serverId] ?? const <Project>[]);
  }

  static Project _change(
    String serverId,
    String projectId,
    Project Function(Project) change,
  ) {
    final projects = _byServer[serverId] ?? <Project>[];
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index < 0) throw const ServerException('Project tidak ditemukan.');
    final updated = change(projects[index]);
    projects[index] = updated;
    return updated;
  }

  /// Builder mengambil project. Status jadi On Progress.
  static Future<Project> claim({
    required String serverId,
    required String projectId,
    required String username,
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (project.hasWorker(username)) {
        throw const ServerException('Kamu sudah mengambil project ini.');
      }
      if (!project.isOpen) {
        throw const ServerException('Project ini sudah tidak bisa diambil.');
      }
      if (project.isFull) {
        throw const ServerException('Slot worker sudah penuh.');
      }
      return project.copyWith(
        status: ProjectStatus.onProgress,
        workers: [...project.workers, username],
      );
    });
  }

  /// Worker mengirim update progress ke thread project.
  static Future<Project> addUpdate({
    required String serverId,
    required String projectId,
    required String author,
    required String text,
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (!project.hasWorker(author)) {
        throw const ServerException(
          'Hanya worker project ini yang bisa mengirim update.',
        );
      }
      if (project.status != ProjectStatus.onProgress) {
        throw const ServerException('Project ini sedang tidak dikerjakan.');
      }
      return project.copyWith(
        updates: [
          ...project.updates,
          ProjectUpdate(
            author: author,
            text: text.trim(),
            sentAt: DateTime.now(),
          ),
        ],
      );
    });
  }

  /// Worker menandai selesai. Project masuk antrean review admin.
  static Future<Project> markDone({
    required String serverId,
    required String projectId,
    required String username,
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (!project.hasWorker(username)) {
        throw const ServerException(
          'Hanya worker project ini yang bisa menandai selesai.',
        );
      }
      if (project.status != ProjectStatus.onProgress) {
        throw const ServerException('Project ini sedang tidak dikerjakan.');
      }
      return project.copyWith(status: ProjectStatus.review);
    });
  }
}
