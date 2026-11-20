import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import 'auth_layout.dart' show kFieldBorder;

const Color kErrorColor = Color(0xFFED4245);
const Color kSuccessColor = Color(0xFF3BA55D);

/// Pesan galat merah di bawah form (pengganti alert/snackbar).
class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kErrorColor.withAlpha(0x1F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kErrorColor.withAlpha(0x66)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.error_outline_rounded,
                size: 16, color: kErrorColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: kErrorColor,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gaya teks galat merah untuk di bawah kolom isian.
const TextStyle kFieldErrorStyle = TextStyle(color: kErrorColor, fontSize: 12);

/// Notifikasi singkat melayang, dengan ikon dan garis berwarna.
void showToast(BuildContext context, String message, {bool error = true}) {
  final color = error ? kErrorColor : kSuccessColor;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withAlpha(0x99)),
        ),
        content: Row(
          children: [
            Icon(
              error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
}

/// Dialog konfirmasi bergaya aplikasi: ikon berwarna, judul, penjelasan,
/// (opsional) isian tambahan, lalu tombol Batal dan konfirmasi.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required Color color,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Batal',
  Widget? body,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: kFieldBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: color.withAlpha(0x2E),
                  child: Icon(icon, color: color, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 16),
                body,
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(cancelLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: color),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
