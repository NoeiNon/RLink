import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../models/server.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/page_body.dart';

class _Stat {
  const _Stat(this.label, this.value);

  final String label;
  final String value;
}

/// Tab Beranda server. Admin melihat token server (untuk disalin dan dikirim
/// ke teman), builder tidak. Angka statistik masih 0 sampai fitur project ada.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.username,
    required this.server,
    required this.role,
  });

  final String username;
  final ServerInfo server;
  final ServerRole role;

  bool get _isAdmin => role == ServerRole.admin;

  @override
  Widget build(BuildContext context) {
    final stats = _isAdmin
        ? const [
            _Stat('Project tersedia', '0'),
            _Stat('Sedang dikerjakan', '0'),
            _Stat('Perlu review', '0'),
          ]
        : const [
            _Stat('Project saya', '0'),
            _Stat('Menunggu review', '0'),
            _Stat('Saldo', '\$0'),
          ];

    return PageBody(
      maxWidth: 600,
      children: [
        Text(
          'Halo, $username!',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isAdmin
              ? 'Kamu admin di ${server.name}.'
              : 'Kamu builder di ${server.name}.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        if (_isAdmin) ...[
          _InfoCard(
            title: 'Token server',
            description:
                'Kirim token ini ke temanmu. Setelah mereka daftar, mereka '
                'pilih Gabung server lalu tempel token ini.',
            child: _TokenBox(token: server.token),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _StatTile(stat: stats[i])),
            ],
          ],
        ),
        const SizedBox(height: 12),
        const _InfoCard(
          title: 'Aktivitas terbaru',
          description: 'Belum ada aktivitas. Project dan progress akan '
              'muncul di sini.',
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.description,
    this.child,
  });

  final String title;
  final String description;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 12),
            child!,
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFieldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menampilkan token server dengan tombol salin.
class _TokenBox extends StatefulWidget {
  const _TokenBox({required this.token});

  final String token;

  @override
  State<_TokenBox> createState() => _TokenBoxState();
}

class _TokenBoxState extends State<_TokenBox> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.token));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2540),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              widget.token,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'monospace',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _copy,
            icon: Icon(
              _copied ? Icons.check_rounded : Icons.copy_rounded,
              size: 18,
            ),
            label: Text(_copied ? 'Tersalin' : 'Salin'),
          ),
        ],
      ),
    );
  }
}
