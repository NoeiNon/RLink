import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../data/mock_server_store.dart';
import '../../models/server.dart';
import '../../models/server_content.dart';
import '../../widgets/auth_layout.dart';
import '../../widgets/server_avatar.dart';

/// Tab Beranda = obrolan (Discussion) server. Admin dan builder melihat
/// obrolan yang sama; bedanya, admin punya strip token di bagian atas.
class OverviewTab extends StatefulWidget {
  const OverviewTab({
    super.key,
    required this.username,
    required this.server,
    required this.role,
  });

  final String username;
  final ServerInfo server;
  final ServerRole role;

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  final _controller = TextEditingController();

  List<ChatMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;

  bool get _isAdmin => widget.role == ServerRole.admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final messages = await MockServerStore.getMessages(widget.server.id);
    if (!mounted) return;
    setState(() {
      _messages = messages;
      _loading = false;
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final message = await MockServerStore.postMessage(
      serverId: widget.server.id,
      author: widget.username,
      isAdmin: _isAdmin,
      text: text,
    );
    if (!mounted) return;
    _controller.clear();
    setState(() {
      _messages = [..._messages, message];
      _sending = false;
    });
  }

  Widget _buildMessages() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Belum ada pesan.\nMulai obrolan pertama!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, height: 1.5),
          ),
        ),
      );
    }

    // reverse: pesan terbaru menempel di bawah, dekat kolom ketik.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _MessageTile(message: _messages[_messages.length - 1 - index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isAdmin) _AdminPanel(token: widget.server.token),
            Expanded(child: _buildMessages()),
            _InputBar(
              controller: _controller,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');

  final clock = '${two(time.hour)}:${two(time.minute)}';
  final now = DateTime.now();
  final today =
      time.year == now.year && time.month == now.month && time.day == now.day;
  return today ? clock : '${two(time.day)}/${two(time.month)} $clock';
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final ChatMessage message;

  Color get _avatarColor {
    var sum = 0;
    for (final unit in message.author.codeUnits) {
      sum += unit;
    }
    return kServerColors[sum % kServerColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        message.author.isEmpty ? '?' : message.author[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _avatarColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    Text(
                      message.author,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _MiniBadge(isAdmin: message.isAdmin),
                    Text(
                      _formatTime(message.sentAt),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                SelectableText(
                  message.text,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0x335865F2) : const Color(0x333BA55D),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Builder',
        style: TextStyle(
          color: isAdmin ? const Color(0xFFB5BCFF) : const Color(0xFF6FD08C),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Strip token di atas obrolan, khusus admin. Dikirim ke teman supaya
/// mereka bisa gabung lewat menu Gabung server.
class _TokenStrip extends StatefulWidget {
  const _TokenStrip({required this.token});

  final String token;

  @override
  State<_TokenStrip> createState() => _TokenStripState();
}

class _TokenStripState extends State<_TokenStrip> {
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
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kFieldBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_outlined, size: 18, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Token server (kirim ke temanmu)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                SelectableText(
                  widget.token,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
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

class _Stat {
  const _Stat(this.label, this.value);

  final String label;
  final String value;
}

/// Panel khusus admin di atas obrolan: token, ringkasan satu baris, dan
/// (kalau dibuka) kotak statistik serta aktivitas terbaru. Bisa dilipat supaya
/// obrolan tetap lega. Otomatis tertutup saat keyboard muncul.
class _AdminPanel extends StatefulWidget {
  const _AdminPanel({required this.token});

  final String token;

  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel> {
  bool _expanded = false;

  // Sementara 0 semua, sampai fitur Project ada.
  static const _stats = [
    _Stat('Project tersedia', '0'),
    _Stat('Sedang dikerjakan', '0'),
    _Stat('Perlu review', '0'),
  ];

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showDetails = _expanded && !keyboardOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TokenStrip(token: widget.token),
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _expanded
                        ? 'Ringkasan server'
                        : '${_stats[0].value} tersedia · '
                            '${_stats[1].value} dikerjakan · '
                            '${_stats[2].value} perlu review',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: showDetails
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (var i = 0; i < _stats.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: _StatTile(stat: _stats[i])),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      const _ActivityCard(),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Container(height: 1, color: kFieldBorder),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kFieldBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktivitas terbaru',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Belum ada aktivitas. Project dan progress akan muncul di sini.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        8,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kFieldBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tulis pesan...',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton.filled(
            tooltip: 'Kirim',
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
