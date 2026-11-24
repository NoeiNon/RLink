import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../data/mock_payroll_store.dart';
import '../data/mock_server_store.dart' show ServerException;
import '../models/payroll.dart';
import '../models/project.dart';
import '../models/server.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/auth_layout.dart' show kFieldBorder;
import '../widgets/money_input.dart';
import '../widgets/payslip_card.dart';
import '../widgets/project_chips.dart';

const _pendingColor = Color(0xFFF28C28);

/// Satu baris bonus/potongan yang sedang diketik admin.
class _Draft {
  final name = TextEditingController();
  final amount = TextEditingController();

  int get value => parseMoney(amount.text);
  bool get empty => name.text.trim().isEmpty && value == 0;
  bool get complete => name.text.trim().isNotEmpty && value > 0;

  void dispose() {
    name.dispose();
    amount.dispose();
  }
}

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
      message:
          'Payment ${formatMoney(project.paymentAmount)} dibagi sesuai '
          'nilai tiap worker.',
      confirmLabel: 'Simpan',
      body: StatefulBuilder(
        builder: (context, setLocal) {
          final shares = MockPayrollStore.split(project.paymentAmount, scores);
          Widget slider(
            String label,
            int value,
            ValueChanged<int> onChanged, {
            String? trailing,
          }) {
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
    await _run(
      () => MockPayrollStore.rate(
        serverId: widget.server.id,
        projectId: project.id,
        scores: scores,
        overall: overall,
      ),
    );
  }

  Future<void> _pay(String worker, List<Receipt> receipts) async {
    final base = receipts.fold<int>(0, (s, r) => s + (r.amount ?? 0));
    final bonuses = <_Draft>[];
    final cuts = <_Draft>[];
    final valid = ValueNotifier<bool>(true);

    int sum(List<_Draft> l) =>
        l.where((d) => d.complete).fold<int>(0, (s, d) => s + d.value);

    final ok = await showConfirmDialog(
      context,
      icon: Icons.receipt_long_rounded,
      color: kSuccessColor,
      title: 'Buat slip gaji?',
      message:
          'Slip $worker berisi ${receipts.length} project '
          '(${formatMoney(base)}). Tambahkan bonus atau potongan bila '
          'perlu, lalu pastikan gajinya sudah kamu transfer.',
      confirmLabel: 'Payed',
      confirmEnabled: valid,
      body: StatefulBuilder(
        builder: (context, setLocal) {
          final total = base + sum(bonuses) - sum(cuts);
          final partial = [
            ...bonuses,
            ...cuts,
          ].any((d) => !d.empty && !d.complete);
          final isValid = total >= 0 && !partial;
          if (valid.value != isValid) {
            // Ubah setelah frame ini selesai supaya tombol tidak dibangun
            // ulang di tengah proses build dialog.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              valid.value = isValid;
            });
          }

          Widget rows(List<_Draft> list) => Column(
            children: [
              for (final d in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: d.name,
                          onChanged: (_) => setLocal(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Keterangan',
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: d.amount,
                          keyboardType: TextInputType.number,
                          inputFormatters: [ThousandsFormatter()],
                          onChanged: (_) => setLocal(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Rp',
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setLocal(() {
                          list.remove(d);
                          d.dispose();
                        }),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
            ],
          );

          Widget heading(String text, VoidCallback onAdd) => Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              heading(
                'Bonus (masuk RINCIAN)',
                () => setLocal(() => bonuses.add(_Draft())),
              ),
              rows(bonuses),
              heading('Potongan', () => setLocal(() => cuts.add(_Draft()))),
              Wrap(
                spacing: 6,
                children: [
                  for (final name in const ['Telat deadline', 'Kasbon'])
                    ActionChip(
                      label: Text(name),
                      onPressed: () =>
                          setLocal(() => cuts.add(_Draft()..name.text = name)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              rows(cuts),
              const Divider(color: kFieldBorder),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total pembayaran',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  Text(
                    formatMoney(total),
                    style: TextStyle(
                      color: total < 0 ? kErrorColor : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              if (total < 0) ...[
                const SizedBox(height: 8),
                const InlineError('Potongan melebihi total rincian.'),
              ] else if (partial) ...[
                const SizedBox(height: 8),
                const InlineError(
                  'Isi keterangan dan nominal, atau hapus barisnya.',
                ),
              ],
            ],
          );
        },
      ),
    );

    final lines = [
      for (final d in bonuses.where((d) => d.complete))
        SlipLine(d.name.text.trim(), d.value),
    ];
    final cutLines = [
      for (final d in cuts.where((d) => d.complete))
        SlipLine(d.name.text.trim(), d.value),
    ];
    for (final d in [...bonuses, ...cuts]) {
      d.dispose();
    }
    valid.dispose();
    if (ok != true) return;
    await _run(
      () => MockPayrollStore.payWorker(
        serverId: widget.server.id,
        worker: worker,
        bonuses: lines,
        deductions: cutLines,
      ),
    );
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
        const Icon(
          Icons.payments_outlined,
          size: 36,
          color: AppColors.textMuted,
        ),
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
                TextSpan(
                  children: [
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
                  ],
                ),
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _archive(List<Payout> payouts) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final p in payouts)
        PayslipCard(payout: p, serverName: widget.server.name),
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
          hint:
              'Ambil dan selesaikan project dulu. Gajimu akan muncul di '
              'sini setelah boss menerima dan menilai hasilnya.',
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
      if (archive.isNotEmpty) ...[_title('SLIP GAJI'), _archive(archive)],
    ];
  }

  List<Widget> _adminView(PayrollData data) {
    final unrated = <String, Project>{
      for (final r in data.unpaid.where((r) => !r.rated))
        r.project.id: r.project,
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
                    onPressed: _busy ? null : () => _pay(e.key, e.value),
                    child: const Text('Buat slip & Payed'),
                  ),
                ),
              ],
            ),
          ),
      ],
      if (data.paid.isNotEmpty) ...[_title('SLIP GAJI'), _archive(data.paid)],
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
