import '../models/project.dart';
import 'mock_server_store.dart' show ServerException;

/// Data project contoh, disimpan di memori (hilang saat app di-restart).
/// Hanya server demo (s_0) yang berisi project; server baru masih kosong
/// sampai admin membuat project.
///
/// TODO: ganti dengan backend. Aturan di sini (siapa boleh claim, slot penuh,
/// hanya worker yang boleh kirim update) harus diperiksa lagi di backend.
/// TODO: pastikan create/accept/decline/setTags hanya bisa oleh admin.
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
        paymentAmount: 2100000,
        paymentNote: 'sekitar',
        detail: 'Lokasi: X 4256 | Y 114 | Z 988.\n'
            'Blueprint: intinya sebuah desa seperti Oliver.',
        deadline: now.add(const Duration(days: 21)),
        maxWorkers: 3,
        author: 'AdminDemo',
        createdAt: now.subtract(const Duration(days: 2)),
        tags: const ['Urgent'],
      ),
      Project(
        id: 'p_2',
        title: 'DV. Resource - Pembersihan Sisa Build',
        from: 'Mandor',
        paymentAmount: 250000,
        detail: 'Banyak chest yang terlantar setelah selesai ngebuild belum '
            'dibersihkan. Dan juga fence-fence yang disekitar belum '
            'dibersihkan.',
        deadline: now.subtract(const Duration(days: 1)),
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
        paymentAmount: 120000,
        detail: 'Rapikan area tambang dan pasang penerangan di semua lorong.',
        deadline: now.subtract(const Duration(days: 5)),
        maxWorkers: 2,
        author: 'AdminDemo',
        createdAt: now.subtract(const Duration(days: 12)),
        status: ProjectStatus.finished,
        workers: const ['BuilderDemo'],
        updates: [
          ProjectUpdate(
            author: 'BuilderDemo',
            text: 'Lorong utara selesai dirapikan.',
            sentAt: now.subtract(const Duration(days: 9)),
          ),
          ProjectUpdate(
            author: 'BuilderDemo',
            text: 'Penerangan terpasang di semua lorong.',
            sentAt: now.subtract(const Duration(days: 7)),
          ),
        ],
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
    List<Blueprint> photos = const [],
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (text.trim().isEmpty && photos.isEmpty) {
        throw const ServerException('Isi penjelasan atau lampirkan foto.');
      }
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
            photos: photos,
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

  /// Admin membuat project baru. Langsung tampil sebagai Available.
  static Future<Project> create({
    required String serverId,
    required String author,
    required String title,
    required String from,
    required int paymentAmount,
    String paymentNote = '',
    required String detail,
    required DateTime deadline,
    required int maxWorkers,
    List<String> tags = const [],
    List<Blueprint> blueprints = const [],
  }) async {
    await _latency();
    final project = Project(
      id: 'p_${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      from: from.trim(),
      paymentAmount: paymentAmount,
      paymentNote: paymentNote.trim(),
      detail: detail.trim(),
      deadline: deadline,
      maxWorkers: maxWorkers,
      author: author,
      createdAt: DateTime.now(),
      tags: tags,
      blueprints: blueprints,
    );
    _byServer.putIfAbsent(serverId, () => <Project>[]).insert(0, project);
    return project;
  }

  /// Admin mengubah tag bebas (Urgent, Delayed, dst.).
  static Future<Project> setTags({
    required String serverId,
    required String projectId,
    required List<String> tags,
  }) async {
    await _latency();
    return _change(
      serverId,
      projectId,
      (project) => project.copyWith(tags: tags),
    );
  }

  /// Admin menerima hasil kerja. Status jadi Finished.
  static Future<Project> accept({
    required String serverId,
    required String projectId,
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (project.status != ProjectStatus.review) {
        throw const ServerException('Project ini tidak sedang direview.');
      }
      return project.copyWith(status: ProjectStatus.finished);
    });
  }

  /// Admin menolak hasil kerja. Project kembali ke On Progress; alasan
  /// (opsional) masuk ke thread progress.
  static Future<Project> decline({
    required String serverId,
    required String projectId,
    required String reviewer,
    String reason = '',
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (project.status != ProjectStatus.review) {
        throw const ServerException('Project ini tidak sedang direview.');
      }
      final note = reason.trim();
      return project.copyWith(
        status: ProjectStatus.onProgress,
        updates: [
          ...project.updates,
          if (note.isNotEmpty)
            ProjectUpdate(
              author: reviewer,
              text: 'Decline: $note',
              sentAt: DateTime.now(),
            ),
        ],
      );
    });
  }

  /// Admin menambah gambar blueprint ke project.
  /// TODO: simpan di storage backend, bukan di memori.
  static Future<Project> addBlueprints({
    required String serverId,
    required String projectId,
    required List<Blueprint> items,
  }) async {
    await _latency();
    return _change(
      serverId,
      projectId,
      (project) =>
          project.copyWith(blueprints: [...project.blueprints, ...items]),
    );
  }

  /// Admin menghapus satu gambar blueprint.
  static Future<Project> removeBlueprint({
    required String serverId,
    required String projectId,
    required int index,
  }) async {
    await _latency();
    return _change(serverId, projectId, (project) {
      if (index < 0 || index >= project.blueprints.length) return project;
      final list = [...project.blueprints]..removeAt(index);
      return project.copyWith(blueprints: list);
    });
  }
}
