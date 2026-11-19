import 'package:flutter/material.dart';

/// Pilihan warna profil server.
const List<Color> kServerColors = [
  Color(0xFF5865F2),
  Color(0xFF3BA55D),
  Color(0xFFED4245),
  Color(0xFFF28C28),
  Color(0xFFB69CFF),
  Color(0xFF2BB8C9),
  Color(0xFFE0568F),
  Color(0xFF8A8F98),
];

/// Pilihan ikon profil server.
const List<IconData> kServerIcons = [
  Icons.construction_rounded,
  Icons.home_work_rounded,
  Icons.castle_rounded,
  Icons.landscape_rounded,
  Icons.forest_rounded,
  Icons.diamond_rounded,
  Icons.bolt_rounded,
  Icons.shield_rounded,
];

/// Profil server: ikon di atas kotak berwarna.
class ServerAvatar extends StatelessWidget {
  const ServerAvatar({
    super.key,
    required this.colorIndex,
    required this.iconIndex,
    this.size = 48,
  });

  final int colorIndex;
  final int iconIndex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = kServerColors[colorIndex % kServerColors.length];
    final icon = kServerIcons[iconIndex % kServerIcons.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}
