import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../models/payroll.dart';
import '../models/project.dart';
import '../../../widgets/auth_layout.dart' show kFieldBorder;

/// Slip gaji satu pembayaran: kop, periode, nomor, RINCIAN, POTONGAN, dan
/// TOTAL PEMBAYARAN. Layar lebar memakai dua kolom seperti slip kertas;
/// layar sempit menumpuknya ke bawah.
class PayslipCard extends StatelessWidget {
  const PayslipCard({
    super.key,
    required this.payout,
    required this.serverName,
    this.showCutLine = true,
  });

  final Payout payout;
  final String serverName;
  final bool showCutLine;

  static const _label = TextStyle(color: AppColors.textMuted, fontSize: 12);
  static const _value = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const _bold = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          children: [
            SizedBox(width: 64, child: Text(k, style: _label)),
            Text(': ', style: _label),
            Expanded(child: Text(v, style: _value)),
          ],
        ),
      );

  Widget _line(String label, int amount) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, style: _value)),
            const SizedBox(width: 8),
            Text(formatMoney(amount), style: _value),
          ],
        ),
      );

  Widget _panel({
    required String title,
    required List<Widget> lines,
    required String totalLabel,
    required int total,
    required bool fill,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kFieldBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Row(
              children: [
                Expanded(child: Text(title, style: _bold)),
                const Text('JUMLAH', style: _bold),
              ],
            ),
          ),
          const Divider(height: 1, color: kFieldBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(children: lines),
          ),
          if (fill) const Spacer() else const SizedBox(height: 4),
          const Divider(height: 1, color: kFieldBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Expanded(child: Text(totalLabel, style: _bold)),
                Text(formatMoney(total), style: _bold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earnings = <Widget>[
      for (final r in payout.receipts) _line(r.project.title, r.amount ?? 0),
      for (final b in payout.bonuses) _line(b.label, b.amount),
    ];
    final deductions = <Widget>[
      if (payout.deductions.isEmpty)
        const Text('-', style: _label)
      else
        for (final d in payout.deductions) _line(d.label, d.amount),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kFieldBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                serverName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Text('SLIP GAJI', style: _bold)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Periode : ${formatPeriod(payout.paidAt)}',
                      style: _bold,
                    ),
                  ),
                  Text('Nomor : ${payout.number}', style: _label),
                ],
              ),
              const SizedBox(height: 10),
              _kv('NAMA', payout.worker),
              _kv('ROLE', 'Builder'),
              _kv('DIBAYAR', formatDate(payout.paidAt)),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, c) {
                  final left = _panel(
                    title: 'RINCIAN',
                    lines: earnings,
                    totalLabel: 'TOTAL RINCIAN',
                    total: payout.totalEarnings,
                    fill: c.maxWidth >= 520,
                  );
                  final right = _panel(
                    title: 'POTONGAN',
                    lines: deductions,
                    totalLabel: 'TOTAL POTONGAN',
                    total: payout.totalDeductions,
                    fill: c.maxWidth >= 520,
                  );
                  if (c.maxWidth >= 520) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 10),
                          Expanded(child: right),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [left, const SizedBox(height: 10), right],
                  );
                },
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(0x26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withAlpha(0x66)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('TOTAL PEMBAYARAN :', style: _bold),
                    ),
                    Text(
                      formatMoney(payout.total),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showCutLine)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              '- - - - - - - - - - - Potong di sini - - - - - - - - - - -',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
      ],
    );
  }
}
