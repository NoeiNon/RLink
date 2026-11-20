import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../data/mock_payroll_store.dart';
import '../../data/mock_server_store.dart' show ServerException;
import '../../models/payroll.dart';
import '../../models/project.dart';
import '../../models/server.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../../widgets/project_chips.dart';

const _pendingColor = Color(0xFFF28C28);

/// Tab Gaji. Builder: receipt miliknya sendiri (pending lalu arsip).
/// Admin: menilai project yang selesai, lalu menandai "Payed" per worker.
class PayrollTab extends StatefulWidget {
  const PayrollTab({
    super.key,
    required this.server,
    required this.username,
    required this.role,
    required this.onOpenProjects,
  });

  final ServerInfo server;
  final String username;
  final ServerRole role;
  final VoidCallback onOpenProjects;

  @override
  State<PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends State<PayrollTab> {
  PayrollData? _data;
  bool _busy = false;

  bool get _isAdmin => widget.role == ServerRole.admin;
  bool _isMe(String name) =>
      name.toLowerCase() == widget.username.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await MockPayrollStore.load(widget.server.id);
    if (!mounted) return;
    setState(() => _data = data);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } on ServerException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rate(Project project) async {
    final scores = {for (final w in project.workers) w: 7};
    var overall = 7;
    final ok = await showConfirmDialog(
      context,
      icon: Icons.star_rounded,
      color: AppColors.primary,
      title: 'Nilai project',
      message: 'Payment ${formatMoney(project.paymentAmount)} dibagi sesuai '
          'nilai tiap worker.',
      confirmLabel: 'Simpan',
      body: StatefulBuilder(
        builder: (context, setLocal) {
          final shares =
              MockPayrollStore.split(project.paymentAmount, scores);
          Widget slider(String label, int value, ValueChanged<int> onChanged,
              {String? trailing}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      trailing == null ? '$value/10' : '$value/10 · $trailing',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
                Slider(
                  value: value.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (v) => setLocal(() => onChanged(v.round())),
                ),
              ],
            );
          }

          return Column(
            children: [
              for (final w in project.workers)
                slider(
                  w,
                  scores[w]!,
                  (v) => scores[w] = v,
                  trailing: formatMoney(shares[w] ?? 0),
                ),
              const Divider(color: kFieldBorder),
              slider('Hasil project', overall, (v) => overall = v),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    await _run(() => MockPayrollStore.rate(
          serverId: widget.server.id,
          projectId: project.id,
          scores: scores,
          overall: overall,
        ));
  }

  Future<void> _pay(String worker, int total) async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.payments_rounded,
      color: kSuccessColor,
      title: 'Tandai sudah dibayar?',
      message: 'Pastikan ${formatMoney(total)} sudah kamu transfer ke '
          '$worker. Receipt akan pindah ke arsip.',
      confirmLabel: 'Payed',
    );
    if (ok != true) return;
    await _run(() => MockPayrollStore.payWorker(
          serverId: widget.server.id,
          worker: worker,
        ));
  }

  // ---- Tampilan ----

  Widget _title(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _box({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kFieldBorder),
        ),
        child: child,
      );

  Widget _empty(String message, {String? hint, bool button = false}) => _box(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.payments_outlined,
                size: 36, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
            if (button) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.onOpenProjects,
                child: const Text('Lihat project'),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      );

  /// Rincian satu receipt; bisa dibuka untuk melihat catatan kerja per hari.
  Widget _receipt(Receipt r, {bool showWorker = false, bool paid = false}) {
    final days = r.days;
    final status = paid
        ? 'Dibayar'
        : (r.rated ? 'Pending' : 'Menunggu penilaian');
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Text(
          showWorker ? '${r.project.title} · ${r.worker}' : r.project.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LabelChip(
                label: status,
                color: paid ? kSuccessColor : _pendingColor,
              ),
              Text(
                r.rated
                    ? 'Nilai ${r.score}/10 · ${formatMoney(r.amount!)}'
                    : 'Payment ${formatMoney(r.project.paymentAmount)}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        children: [
          if (r.overall != null)
            Text(
              'Hasil project: ${r.overall}/10',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Terekam ${days.length} hari kerja',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final d in days)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '${formatDate(d.day)}  ',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: d.notes.join(' | '),
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ]),
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _archive(List<Payout> payouts) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final p in payouts)
            _box(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  title: Text(
                    _isAdmin ? '${p.worker} · ${formatMoney(p.total)}'
                        : formatMoney(p.total),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    'Dibayar ${formatDate(p.paidAt)} · '
                    '${p.receipts.length} project',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  children: [for (final r in p.receipts) _receipt(r, paid: true)],
                ),
              ),
            ),
        ],
      );

  List<Widget> _builderView(PayrollData data) {
    final mine = data.unpaid.where((r) => _isMe(r.worker)).toList();
    final archive = data.paid.where((p) => _isMe(p.worker)).toList();
    final total = mine.fold<int>(0, (sum, r) => sum + (r.amount ?? 0));
    return [
      if (mine.isEmpty)
        _empty(
          'Belum ada proyek yang kamu kerjakan',
          hint: 'Ambil dan selesaikan project dulu. Gajimu akan muncul di '
              'sini setelah admin menerima dan menilai hasilnya.',
          button: true,
        )
      else ...[
        _box(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total pending',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              Text(
                formatMoney(total),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _title('GAJI PENDING'),
        for (final r in mine) _box(child: _receipt(r)),
      ],
      if (archive.isNotEmpty) ...[
        _title('ARSIP'),
        _archive(archive),
      ],
    ];
  }

  List<Widget> _adminView(PayrollData data) {
    final unrated = <String, Project>{
      for (final r in data.unpaid.where((r) => !r.rated)) r.project.id: r.project,
    }.values.toList();
    final byWorker = <String, List<Receipt>>{};
    for (final r in data.unpaid.where((r) => r.rated)) {
      (byWorker[r.worker] ??= []).add(r);
    }
    if (unrated.isEmpty && byWorker.isEmpty && data.paid.isEmpty) {
      return [
        _empty(
          'Belum ada gaji untuk diproses',
          hint: 'Gaji muncul setelah kamu menekan Accept pada project.',
        ),
      ];
    }
    return [
      if (unrated.isNotEmpty) ...[
        _title('PERLU DINILAI'),
        for (final p in unrated)
          _box(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.workers.join(', ')} · '
                        '${formatMoney(p.paymentAmount)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _busy ? null : () => _rate(p),
                  child: const Text('Nilai'),
                ),
              ],
            ),
          ),
      ],
      if (byWorker.isNotEmpty) ...[
        _title('BELUM DIBAYAR'),
        for (final e in byWorker.entries)
          _box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formatMoney(
                        e.value.fold<int>(0, (s, r) => s + (r.amount ?? 0)),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                for (final r in e.value) _receipt(r),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _pay(
                              e.key,
                              e.value.fold<int>(
                                  0, (s, r) => s + (r.amount ?? 0)),
                            ),
                    child: const Text('Payed'),
                  ),
                ),
              ],
            ),
          ),
      ],
      if (data.paid.isNotEmpty) ...[
        _title('ARSIP'),
        _archive(data.paid),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const Center(child: CircularProgressIndicator());
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: _isAdmin ? _adminView(data) : _builderView(data),
          ),
        ),
      ),
    );
  }
}
