import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Pesan pribadi (DM). Isinya menyusul; nanti juga tempat undangan hire
/// dari boss yang bisa diterima langsung dari pesan.
class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada pesan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Percakapan pribadimu dengan pengguna lain akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}
