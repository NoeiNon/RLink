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
    this.photos = const [],
  });

  final String author;
  final String text;
  final DateTime sentAt;

  /// Foto lapangan yang dilampirkan worker.
  final List<Blueprint> photos;
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
    required this.paymentAmount,
    this.paymentNote = '',
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
  /// Nominal dalam dollar server (angka, supaya bisa dihitung di tab Gaji).
  final int paymentAmount;

  /// Catatan bebas: "sekitar", "bisa nego", dst.
  final String paymentNote;
  final String detail;
  final DateTime deadline;
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

  String get paymentLabel {
    final amount = formatMoney(paymentAmount);
    return paymentNote.isEmpty ? amount : '$amount · $paymentNote';
  }

  /// Lewat tanggal deadline dan belum selesai. Tag Delayed muncul otomatis.
  bool get isOverdue {
    if (status == ProjectStatus.finished) return false;
    final end = DateTime(deadline.year, deadline.month, deadline.day + 1);
    return !DateTime.now().isBefore(end);
  }

  /// Tag buatan admin ditambah Delayed otomatis (Delayed manual diabaikan).
  List<String> get displayTags => [
        ...tags.where((t) => t.toLowerCase() != 'delayed'),
        if (isOverdue) 'Delayed',
      ];

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
      paymentAmount: paymentAmount,
      paymentNote: paymentNote,
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

/// 5 Jan 2026 -> "05/01/2026"
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  return '${diff.inDays} hari lalu';
}

/// 21000 -> "$21.000"
String formatMoney(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
    out.write(digits[i]);
  }
  return '\$${value < 0 ? '-' : ''}$out';
}
