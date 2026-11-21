import '../models/payroll.dart';
import '../models/project.dart';
import 'mock_server_store.dart' show ServerException;
import 'supabase_project_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementasi modul gaji & slip pembayaran menggunakan Supabase.
class SupabasePayrollStore {
  SupabasePayrollStore._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Payment dibagi sesuai perbandingan nilai.
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

  /// Memuat data payroll (belum dibayar & riwayat slip yang sudah dibayar).
  static Future<PayrollData> load(String serverId) async {
    try {
      final projects = await SupabaseProjectStore.list(serverId);

      // Ambil semua rating yang sudah ada di server ini
      final ratingsRes = await _client
          .from('payroll_ratings')
          .select()
          .eq('server_id', serverId);

      final ratingMap = <String, Map<String, dynamic>>{};
      for (final r in (ratingsRes as List)) {
        final key = '${r['project_id']}|${(r['worker_name'] as String).toLowerCase()}';
        ratingMap[key] = r as Map<String, dynamic>;
      }

      // Ambil semua slip payout beserta relasinya
      final payoutsRes = await _client
          .from('payroll_payouts')
          .select('''
            id,
            number,
            worker_name,
            paid_at,
            payroll_slip_lines(type, label, amount),
            payroll_payout_receipts(
              payroll_ratings(project_id, worker_name, score, overall, amount)
            )
          ''')
          .eq('server_id', serverId)
          .order('paid_at', ascending: false);

      final paidRatingKeys = <String>{};
      final paidList = <Payout>[];

      for (final p in (payoutsRes as List)) {
        final lines = (p['payroll_slip_lines'] as List? ?? []);
        final bonuses = <SlipLine>[];
        final deductions = <SlipLine>[];

        for (final l in lines) {
          final amt = (l['amount'] as num?)?.toInt() ?? 0;
          final lbl = l['label'] as String? ?? '';
          if (l['type'] == 'bonus') {
            bonuses.add(SlipLine(lbl, amt));
          } else {
            deductions.add(SlipLine(lbl, amt));
          }
        }

        final receipts = <Receipt>[];
        final pReceipts = (p['payroll_payout_receipts'] as List? ?? []);
        for (final pr in pReceipts) {
          final prData = pr['payroll_ratings'] as Map<String, dynamic>?;
          if (prData == null) continue;

          final projId = prData['project_id'] as String;
          final wName = prData['worker_name'] as String;
          paidRatingKeys.add('$projId|${wName.toLowerCase()}');

          final project = projects.firstWhere(
            (item) => item.id == projId,
            orElse: () => Project(
              id: projId,
              title: 'Project Arsip',
              from: '',
              paymentAmount: 0,
              detail: '',
              deadline: DateTime.now(),
              maxWorkers: 1,
              author: '',
              createdAt: DateTime.now(),
            ),
          );

          receipts.add(
            Receipt(
              project: project,
              worker: wName,
              score: prData['score'] as int?,
              overall: prData['overall'] as int?,
              amount: (prData['amount'] as num?)?.toInt(),
            ),
          );
        }

        paidList.add(
          Payout(
            id: p['id'] as String,
            number: p['number'] as int? ?? 1,
            worker: p['worker_name'] as String? ?? '',
            receipts: receipts,
            paidAt: DateTime.tryParse(p['paid_at'] as String? ?? '') ??
                DateTime.now(),
            bonuses: bonuses,
            deductions: deductions,
          ),
        );
      }

      // Hitung unpaid
      final unpaid = <Receipt>[];
      for (final p in projects) {
        if (p.status != ProjectStatus.finished) continue;

        for (final w in p.workers) {
          final key = '${p.id}|${w.toLowerCase()}';
          if (paidRatingKeys.contains(key)) continue;

          final rData = ratingMap[key];
          unpaid.add(
            Receipt(
              project: p,
              worker: w,
              score: rData?['score'] as int?,
              overall: rData?['overall'] as int?,
              amount: (rData?['amount'] as num?)?.toInt(),
            ),
          );
        }
      }

      return PayrollData(unpaid: unpaid, paid: paidList);
    } catch (e) {
      throw ServerException('Gagal memuat payroll: ${e.toString()}');
    }
  }

  /// Admin menilai pekerjaan builder pada project finished.
  static Future<void> rate({
    required String serverId,
    required String projectId,
    required Map<String, int> scores,
    required int overall,
  }) async {
    try {
      final projects = await SupabaseProjectStore.list(serverId);
      final project = projects.firstWhere((p) => p.id == projectId);
      final amounts = split(project.paymentAmount, scores);

      for (final entry in scores.entries) {
        final worker = entry.key;
        final score = entry.value;
        final amount = amounts[worker] ?? 0;

        await _client.from('payroll_ratings').upsert({
          'server_id': serverId,
          'project_id': projectId,
          'worker_name': worker,
          'score': score,
          'overall': overall,
          'amount': amount,
        }, onConflict: 'server_id,project_id,worker_name');
      }
    } catch (e) {
      throw ServerException('Gagal menyimpan nilai: ${e.toString()}');
    }
  }

  /// Membayar gaji worker dan menerbitkan slip payout.
  static Future<void> payWorker({
    required String serverId,
    required String worker,
    List<SlipLine> bonuses = const [],
    List<SlipLine> deductions = const [],
  }) async {
    try {
      // Ambil rating yang belum dibayar untuk worker ini
      final ratingsRes = await _client
          .from('payroll_ratings')
          .select('id, amount')
          .eq('server_id', serverId)
          .ilike('worker_name', worker);

      // Ambil payout yang sudah ada untuk mendapatkan nomor urut slip
      final countRes = await _client
          .from('payroll_payouts')
          .select('id')
          .eq('server_id', serverId);
      final nextNumber = (countRes as List).length + 1;

      final payoutInsert = await _client.from('payroll_payouts').insert({
        'server_id': serverId,
        'number': nextNumber,
        'worker_name': worker,
        'paid_at': DateTime.now().toIso8601String(),
      }).select().single();

      final payoutId = payoutInsert['id'] as String;

      // Hubungkan rating ke payout
      for (final r in (ratingsRes as List)) {
        await _client.from('payroll_payout_receipts').insert({
          'payout_id': payoutId,
          'rating_id': r['id'],
        });
      }

      // Masukkan bonus dan potongan
      for (final b in bonuses) {
        await _client.from('payroll_slip_lines').insert({
          'payout_id': payoutId,
          'type': 'bonus',
          'label': b.label.trim(),
          'amount': b.amount,
        });
      }

      for (final d in deductions) {
        await _client.from('payroll_slip_lines').insert({
          'payout_id': payoutId,
          'type': 'deduction',
          'label': d.label.trim(),
          'amount': d.amount,
        });
      }
    } catch (e) {
      throw ServerException('Gagal memproses pembayaran: ${e.toString()}');
    }
  }
}
