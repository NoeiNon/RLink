import '../core/supabase_config.dart';
import '../models/payroll.dart';
import '../models/project.dart';
import 'mock_project_store.dart';
import 'mock_server_store.dart' show ServerException;
import 'supabase_payroll_store.dart';

class _Rating {
  const _Rating(this.scores, this.overall);

  final Map<String, int> scores;
  final int overall;
}

/// Data gaji contoh di memori. Alur: project Finished -> admin menilai tiap
/// worker dan hasil project -> payment dibagi sesuai nilai -> admin menekan
/// "Payed" -> receipt masuk arsip.
///
/// TODO: ganti dengan backend; pembagian uang dan status bayar harus dihitung
/// dan dicek di server, bukan di aplikasi.
class MockPayrollStore {
  MockPayrollStore._();

  static final Map<String, Map<String, _Rating>> _ratings = {};
  static final Map<String, Set<String>> _paidKeys = {};
  static final Map<String, List<Payout>> _payouts = {};
  static int _counter = 1;

  /// Payment dibagi sesuai nilai. Sisa pembulatan masuk ke nilai tertinggi
  /// supaya totalnya tepat sama dengan payment.
  static Map<String, int> split(int payment, Map<String, int> scores) {
    final total = scores.values.fold<int>(0, (a, b) => a + b);
    final out = <String, int>{};
    for (final e in scores.entries) {
      out[e.key] = total == 0 ? 0 : (payment * e.value) ~/ total;
    }
    final given = out.values.fold<int>(0, (a, b) => a + b);
    final left = total == 0 ? 0 : payment - given;
    if (left > 0) {
      var topKey = scores.keys.first;
      for (final e in scores.entries) {
        if (e.value > (scores[topKey] ?? 0)) topKey = e.key;
      }
      out.update(topKey, (v) => v + left);
    }
    return out;
  }

  static String _key(String projectId, String worker) =>
      '$projectId|${worker.toLowerCase()}';

  static Future<List<Receipt>> _unpaid(String serverId) async {
    final projects = await MockProjectStore.list(serverId);
    final paid = _paidKeys[serverId] ?? const <String>{};
    final result = <Receipt>[];
    for (final p in projects) {
      if (p.status != ProjectStatus.finished) continue;
      final rating = _ratings[serverId]?[p.id];
      final amounts = rating == null
          ? const <String, int>{}
          : split(p.paymentAmount, rating.scores);
      for (final w in p.workers) {
        if (paid.contains(_key(p.id, w))) continue;
        result.add(Receipt(
          project: p,
          worker: w,
          score: rating?.scores[w],
          overall: rating?.overall,
          amount: amounts[w],
        ));
      }
    }
    return result;
  }

  static Future<PayrollData> load(String serverId) async {
    if (SupabaseConfig.isConfigured) {
      return SupabasePayrollStore.load(serverId);
    }
    final unpaid = await _unpaid(serverId);
    final paid = List<Payout>.of(_payouts[serverId] ?? const <Payout>[])
      ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return PayrollData(unpaid: unpaid, paid: paid);
  }

  /// Admin menilai semua worker satu project (1-10) dan hasil keseluruhannya.
  static Future<void> rate({
    required String serverId,
    required String projectId,
    required Map<String, int> scores,
    required int overall,
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabasePayrollStore.rate(
        serverId: serverId,
        projectId: projectId,
        scores: scores,
        overall: overall,
      );
    }
    final unpaid = await _unpaid(serverId);
    final targets = unpaid.where((r) => r.project.id == projectId).toList();
    if (targets.isEmpty) {
      throw const ServerException('Project ini tidak bisa dinilai.');
    }
    if (targets.any((r) => r.rated)) {
      throw const ServerException('Project ini sudah dinilai.');
    }
    bool valid(int v) => v >= 1 && v <= 10;
    if (!valid(overall) ||
        targets.any((r) => !valid(scores[r.worker] ?? 0))) {
      throw const ServerException('Nilai harus 1 sampai 10.');
    }
    (_ratings[serverId] ??= {})[projectId] = _Rating(scores, overall);
  }

  /// Admin menandai gaji seorang worker sudah ditransfer. Semua receipt
  /// tertunda worker itu digabung jadi satu arsip.
  static Future<void> payWorker({
    required String serverId,
    required String worker,
    List<SlipLine> bonuses = const [],
    List<SlipLine> deductions = const [],
  }) async {
    if (SupabaseConfig.isConfigured) {
      return SupabasePayrollStore.payWorker(
        serverId: serverId,
        worker: worker,
        bonuses: bonuses,
        deductions: deductions,
      );
    }
    final unpaid = await _unpaid(serverId);
    final mine = unpaid
        .where((r) => r.rated && r.worker.toLowerCase() == worker.toLowerCase())
        .toList();
    if (mine.isEmpty) {
      throw const ServerException('Belum ada gaji yang bisa dibayar.');
    }
    bool bad(SlipLine l) => l.label.trim().isEmpty || l.amount <= 0;
    if (bonuses.any(bad) || deductions.any(bad)) {
      throw const ServerException('Nama dan nominal harus diisi semua.');
    }
    int sum(Iterable<int> v) => v.fold(0, (a, b) => a + b);
    final earnings = sum(mine.map((r) => r.amount ?? 0)) +
        sum(bonuses.map((l) => l.amount));
    if (sum(deductions.map((l) => l.amount)) > earnings) {
      throw const ServerException(
        'Potongan tidak boleh melebihi total rincian.',
      );
    }
    final keys = _paidKeys.putIfAbsent(serverId, () => <String>{});
    for (final r in mine) {
      keys.add(_key(r.project.id, r.worker));
    }
    (_payouts[serverId] ??= []).add(Payout(
      id: 'pay_${_counter++}',
      number: (_payouts[serverId]?.length ?? 0) + 1,
      worker: mine.first.worker,
      receipts: mine,
      paidAt: DateTime.now(),
      bonuses: [for (final b in bonuses) SlipLine(b.label.trim(), b.amount)],
      deductions: [
        for (final d in deductions) SlipLine(d.label.trim(), d.amount),
      ],
    ));
  }
}
