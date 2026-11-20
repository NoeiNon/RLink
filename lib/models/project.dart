import 'dart:typed_data';

/// Status project diatur sistem mengikuti alurnya (bukan dipilih manual):
/// available -> onProgress (ada yang claim) -> review (mark as done)
/// -> finished (admin Accept) atau kembali ke onProgress (admin Decline).
enum ProjectStatus { available, onProgress, review, finished }

extension ProjectStatusLabel on ProjectStatus {
  String get label => switch (this) {
    ProjectStatus.available => 'Available',
    ProjectStatus.onProgress => 'On Progress',
    ProjectStatus.review => 'Menunggu review',
    ProjectStatus.finished => 'Finished',
  };
}

/// Satu update progress di thread sebuah project.
class ProjectUpdate {
  const ProjectUpdate({
    required this.author,
    required this.text,
    required this.sentAt,
  });

  final String author;
  final String text;
  final DateTime sentAt;
}

/// Gambar blueprint yang dilampirkan admin ke sebuah project.
class Blueprint {
  const Blueprint({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class Project {
  const Project({
    required this.id,
    required this.title,
    required this.from,
    required this.payment,
    required this.detail,
    required this.deadline,
    required this.maxWorkers,
    required this.author,
    required this.createdAt,
    this.tags = const [],
    this.status = ProjectStatus.available,
    this.workers = const [],
    this.updates = const [],
    this.blueprints = const [],
  });

  final String id;
  final String title;
  final String from;
  final String payment;
  final String detail;
  final String deadline;
  final int maxWorkers;
  final String author;
  final DateTime createdAt;

  /// Label bebas buatan admin (Urgent, Delayed, dst.).
  final List<String> tags;
  final ProjectStatus status;
  final List<String> workers;
  final List<ProjectUpdate> updates;
  final List<Blueprint> blueprints;

  bool hasWorker(String username) {
    final key = username.trim().toLowerCase();
    return workers.any((worker) => worker.toLowerCase() == key);
  }

  bool get isFull => workers.length >= maxWorkers;

  /// Masih bisa diambil/dikerjakan (belum masuk review atau selesai).
  bool get isOpen =>
      status == ProjectStatus.available || status == ProjectStatus.onProgress;

  Project copyWith({
    List<String>? tags,
    ProjectStatus? status,
    List<String>? workers,
    List<ProjectUpdate>? updates,
    List<Blueprint>? blueprints,
  }) {
    return Project(
      id: id,
      title: title,
      from: from,
      payment: payment,
      detail: detail,
      deadline: deadline,
      maxWorkers: maxWorkers,
      author: author,
      createdAt: createdAt,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      workers: workers ?? this.workers,
      updates: updates ?? this.updates,
      blueprints: blueprints ?? this.blueprints,
    );
  }
}

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}
