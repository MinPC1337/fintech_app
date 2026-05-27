import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

void showNotificationDialog(
  BuildContext context,
  String title,
  String message,
  Color color,
  IconData icon, {
  VoidCallback? onOkPressed,
  Duration autoCloseDuration = const Duration(seconds: 2),
}) {
  bool alreadyClosed = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      Future.delayed(autoCloseDuration, () {
        if (ctx.mounted && !alreadyClosed) {
          alreadyClosed = true;
          Navigator.of(ctx).pop();
          if (onOkPressed != null) onOkPressed();
        }
      });

      return AlertDialog(
        backgroundColor: kBgColor,
        elevation: 20,
        shadowColor: color.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withValues(alpha: 0.2)),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 64),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: kTextSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  backgroundColor: color.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  if (!alreadyClosed) {
                    alreadyClosed = true;
                    Navigator.of(ctx).pop();
                    if (onOkPressed != null) onOkPressed();
                  }
                },
                child: const Text(
                  'ĐÃ HIỂU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    },
  ).then((_) => alreadyClosed = true);
}
