import 'package:flutter/material.dart';

import '../models/project.dart';

Color statusColor(ProjectStatus status) => switch (status) {
      ProjectStatus.available => const Color(0xFF3BA55D),
      ProjectStatus.onProgress => const Color(0xFF7C8AFF),
      ProjectStatus.review => const Color(0xFFF28C28),
      ProjectStatus.finished => const Color(0xFF8A8F98),
    };

Color tagColor(String tag) => tag.toLowerCase() == 'delayed'
    ? const Color(0xFFED4245)
    : const Color(0xFFB69CFF);

/// Chip kecil berwarna untuk status dan tag project.
class LabelChip extends StatelessWidget {
  const LabelChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(0x33),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
