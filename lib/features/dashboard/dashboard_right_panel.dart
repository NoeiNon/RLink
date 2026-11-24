import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/auth_layout.dart' show kFieldBorder;
import '../../widgets/auth_split_layout.dart' show compactInputDecoration;

/// Satu agenda atau pengingat di jadwal pribadi (sementara di memori).
/// Nanti jadwal ini disambungkan dengan project.
class ScheduleItem {
  const ScheduleItem({
    required this.title,
    required this.date,
    this.isReminder = false,
    this.hasTime = false,
  });

  final String title;

  /// Tanggal; jam dan menit dipakai kalau [hasTime] true.
  final DateTime date;
  final bool isReminder;
  final bool hasTime;
}

const _monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
const _dayNames = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];
const _weekdayShort = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _two(int v) => v.toString().padLeft(2, '0');

String _timeLabel(ScheduleItem e) => e.hasTime
    ? '${_two(e.date.hour)}:${_two(e.date.minute)}'
    : 'Sepanjang hari';

String _dateLabel(DateTime d) =>
    '${_dayNames[d.weekday - 1]}, ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

/// Pengingat yang jatuh hari ini; dipakai untuk notifikasi.
List<ScheduleItem> todaysReminders(List<ScheduleItem> events) {
  final now = DateTime.now();
  return [
    for (final e in events)
      if (e.isReminder && _sameDay(e.date, now)) e,
  ]..sort((a, b) => a.date.compareTo(b.date));
}

/// Daftar notifikasi. Sekarang berisi pengingat hari ini; lamaran dan
/// undangan menyusul.
Future<void> showNotificationsDialog(
  BuildContext context,
  List<ScheduleItem> events,
) {
  final items = todaysReminders(events);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Notifikasi', style: TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 340,
        child: items.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Belum ada notifikasi.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in items)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.notifications_active_outlined,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      title: Text(
                        e.title,
                        style: const TextStyle(fontSize: 13.5),
                      ),
                      subtitle: Text(
                        'Pengingat hari ini · ${_timeLabel(e)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

/// Sidebar kanan: jadwal pribadi berbentuk kalender bulanan, lengkap dengan
/// agenda dan pengingat, serta ikon lonceng untuk melihat notifikasi.
class DashboardRightPanel extends StatefulWidget {
  const DashboardRightPanel({
    super.key,
    required this.events,
    required this.onAddEvent,
    required this.onRemoveEvent,
  });

  final List<ScheduleItem> events;
  final ValueChanged<ScheduleItem> onAddEvent;
  final ValueChanged<ScheduleItem> onRemoveEvent;

  @override
  State<DashboardRightPanel> createState() => _DashboardRightPanelState();
}

class _DashboardRightPanelState extends State<DashboardRightPanel> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  List<ScheduleItem> _eventsOn(DateTime day) =>
      [
        for (final e in widget.events)
          if (_sameDay(e.date, day)) e,
      ]..sort((a, b) {
        if (a.hasTime != b.hasTime) return a.hasTime ? 1 : -1;
        return a.date.compareTo(b.date);
      });

  Future<void> _add() async {
    final item = await showDialog<ScheduleItem>(
      context: context,
      builder: (_) => _AddDialog(initialDate: _selected),
    );
    if (item == null) return;
    widget.onAddEvent(item);
    setState(() {
      _selected = DateTime(item.date.year, item.date.month, item.date.day);
      _month = DateTime(item.date.year, item.date.month);
    });
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final cells = ((lead + daysInMonth) / 7).ceil() * 7;
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Bulan sebelumnya',
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              onPressed: () => _shiftMonth(-1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_monthNames[_month.month - 1]} ${_month.year}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Bulan berikutnya',
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              onPressed: () => _shiftMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final d in _weekdayShort)
              Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < cells / 7; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: _dayCell(
                    DateTime(
                      _month.year,
                      _month.month,
                      1 + week * 7 + d - lead,
                    ),
                    today,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(DateTime day, DateTime today) {
    final inMonth = day.month == _month.month;
    final selected = _sameDay(day, _selected);
    final isToday = _sameDay(day, today);
    final hasEvent = widget.events.any((e) => _sameDay(e.date, day));

    final Color textColor = selected
        ? Colors.white
        : inMonth
        ? AppColors.textPrimary
        : const Color(0x739A96AB);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() {
        _selected = DateTime(day.year, day.month, day.day);
        if (!inMonth) _month = DateTime(day.year, day.month);
      }),
      child: SizedBox(
        height: 36,
        child: Center(
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !selected
                  ? Border.all(color: AppColors.accent)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (hasEvent)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _eventTile(ScheduleItem e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kFieldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0x335865F2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                e.isReminder
                    ? Icons.notifications_none_rounded
                    : Icons.event_note_rounded,
                size: 16,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${e.isReminder ? 'Pengingat' : 'Agenda'} · ${_timeLabel(e)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hapus',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.close_rounded,
                size: 16,
                color: AppColors.textMuted,
              ),
              onPressed: () => widget.onRemoveEvent(e),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsOn(_selected);
    final hasAlert = todaysReminders(widget.events).isNotEmpty;

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
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Jadwal',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Notifikasi',
                    visualDensity: VisualDensity.compact,
                    icon: Badge(
                      isLabelVisible: hasAlert,
                      smallSize: 8,
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                      ),
                    ),
                    onPressed: () =>
                        showNotificationsDialog(context, widget.events),
                  ),
                  IconButton(
                    tooltip: 'Tambah agenda',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_rounded, size: 22),
                    onPressed: _add,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: _calendar(),
            ),
            const Divider(height: 1, color: kFieldBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                _dateLabel(_selected),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: dayEvents.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Belum ada agenda atau pengingat. Tekan + untuk '
                        'menambah.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      children: [for (final e in dayEvents) _eventTile(e)],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDialog extends StatefulWidget {
  const _AddDialog({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final _title = TextEditingController();
  late DateTime _date = widget.initialDate;
  TimeOfDay? _time;
  bool _reminder = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final t = _time;
    Navigator.pop(
      context,
      ScheduleItem(
        title: title,
        date: DateTime(
          _date.year,
          _date.month,
          _date.day,
          t?.hour ?? 0,
          t?.minute ?? 0,
        ),
        isReminder: _reminder,
        hasTime: t != null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Tambah jadwal', style: TextStyle(fontSize: 15)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Agenda'),
                  selected: !_reminder,
                  onSelected: (_) => setState(() => _reminder = false),
                ),
                ChoiceChip(
                  label: const Text('Pengingat'),
                  selected: _reminder,
                  onSelected: (_) => setState(() => _reminder = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              autofocus: true,
              style: const TextStyle(fontSize: 13.5),
              decoration: compactInputDecoration(
                label: _reminder ? 'Pengingat' : 'Nama agenda',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 15),
                    label: Text('${_date.day} ${_monthNames[_date.month - 1]}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded, size: 15),
                    label: Text(
                      _time == null
                          ? 'Tambah jam'
                          : '${_two(_time!.hour)}:${_two(_time!.minute)}',
                    ),
                  ),
                ),
              ],
            ),
            if (_time != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _time = null),
                  child: const Text('Hapus jam'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
