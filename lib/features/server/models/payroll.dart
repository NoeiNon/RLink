import 'project.dart';

/// Catatan kerja satu hari: tanggal dan isi update worker di hari itu.
class WorkDay {
  const WorkDay(this.day, this.notes);

  final DateTime day;
  final List<String> notes;
}

/// Satu baris gaji: seorang worker di satu project yang sudah Finished.
/// [score] dan [amount] kosong selama admin belum memberi penilaian.
class Receipt {
  const Receipt({
    required this.project,
    required this.worker,
    this.score,
    this.overall,
    this.amount,
  });

  final Project project;
  final String worker;

  /// Nilai worker (1-10) dan nilai hasil project secara keseluruhan (1-10).
  final int? score;
  final int? overall;
  final int? amount;

  bool get rated => score != null;

  /// Hari-hari saat worker ini mengirim progress, urut dari yang terlama.
  List<WorkDay> get days {
    final byDay = <DateTime, List<String>>{};
    for (final u in project.updates) {
      if (u.author.toLowerCase() != worker.toLowerCase()) continue;
      final day = DateTime(u.sentAt.year, u.sentAt.month, u.sentAt.day);
      final note = [
        if (u.text.isNotEmpty) u.text,
        if (u.photos.isNotEmpty) '${u.photos.length} foto',
      ].join(' · ');
      (byDay[day] ??= []).add(note);
    }
    final keys = byDay.keys.toList()..sort();
    return [for (final k in keys) WorkDay(k, byDay[k]!)];
  }
}

/// Satu baris tambahan di slip: bonus (RINCIAN) atau potongan (POTONGAN).
class SlipLine {
  const SlipLine(this.label, this.amount);

  final String label;
  final int amount;
}

/// Satu pembayaran dari admin = satu slip gaji: semua receipt worker yang
/// tertunda digabung, ditambah bonus dan dikurangi potongan.
class Payout {
  const Payout({
    required this.id,
    required this.number,
    required this.worker,
    required this.receipts,
    required this.paidAt,
    this.bonuses = const [],
    this.deductions = const [],
  });

  final String id;

  /// Nomor slip, berurutan per server.
  final int number;
  final String worker;
  final List<Receipt> receipts;
  final DateTime paidAt;
  final List<SlipLine> bonuses;
  final List<SlipLine> deductions;

  int get totalEarnings =>
      receipts.fold(0, (sum, r) => sum + (r.amount ?? 0)) +
      bonuses.fold(0, (sum, l) => sum + l.amount);
  int get totalDeductions => deductions.fold(0, (sum, l) => sum + l.amount);

  /// TOTAL PEMBAYARAN = total rincian - total potongan.
  int get total => totalEarnings - totalDeductions;
}

class PayrollData {
  const PayrollData({required this.unpaid, required this.paid});

  /// Belum dibayar (belum dinilai atau sudah dinilai tapi menunggu transfer).
  final List<Receipt> unpaid;
  final List<Payout> paid;
}
