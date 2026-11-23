import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;

/// Satu agenda di jadwal pribadi (disimpan sementara di memori).
class ScheduleItem {
  const ScheduleItem({required this.title, required this.date});

  final String title;
  final DateTime date;
}

/// Sidebar kanan: Pesan (DM), Notifikasi, dan Jadwal yang diatur sendiri.
/// Pesan dan Notifikasi masih kosong sampai fiturnya dibuat.
class DashboardRightPanel extends StatefulWidget {
  const DashboardRightPanel({
    super.key,
    required this.events,
    required this.onAddEvent,
    required this.onRemoveEvent,
    this.initialTab = 0,
  });

  final List<ScheduleItem> events;
  final ValueChanged<ScheduleItem> onAddEvent;
  final ValueChanged<ScheduleItem> onRemoveEvent;
  final int initialTab;

  @override
  State<DashboardRightPanel> createState() => _DashboardRightPanelState();
}

class _DashboardRightPanelState extends State<DashboardRightPanel> {
  late int _tab = widget.initialTab;

  static const _labels = ['Pesan', 'Notifikasi', 'Jadwal'];

  Future<void> _addEvent() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah jadwal'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(hintText: 'Contoh: Interview tim'),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    Future<void>.delayed(
      const Duration(milliseconds: 400),
      controller.dispose,
    );

    final text = title?.trim() ?? '';
    if (text.isEmpty) return;
    widget.onAddEvent(ScheduleItem(title: text, date: date));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: kFieldBorder)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  for (var i = 0; i < _labels.length; i++) ...[
                    _TabChip(
                      label: _labels[i],
                      selected: _tab == i,
                      onTap: () => setState(() => _tab = i),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: kFieldBorder),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    switch (_tab) {
      case 0:
        return const _EmptyState(
          icon: Icons.chat_bubble_outline_rounded,
          title: 'Belum ada pesan',
          description: 'Percakapan pribadimu dengan pengguna lain akan muncul di sini.',
        );
      case 1:
        return const _EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'Belum ada notifikasi',
          description: 'Undangan, kabar dari server, dan pembaruan lain akan muncul di sini.',
        );
      default:
        return _schedule();
    }
  }

  Widget _schedule() {
    final events = [...widget.events]..sort((a, b) => a.date.compareTo(b.date));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah jadwal'),
            ),
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const _EmptyState(
                  icon: Icons.event_outlined,
                  title: 'Belum ada jadwal',
                  description: 'Atur sendiri agendamu, misalnya interview, rapat, atau deadline.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, i) => _EventTile(
                    item: events[i],
                    onRemove: () => widget.onRemoveEvent(events[i]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0x335865F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 34, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.item, required this.onRemove});

  final ScheduleItem item;
  final VoidCallback onRemove;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final d = item.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kFieldBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x335865F2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  '${d.day}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _months[d.month - 1],
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hapus',
            iconSize: 18,
            color: AppColors.textMuted,
            icon: const Icon(Icons.close_rounded),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
