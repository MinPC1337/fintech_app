import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'dart:ui';

void showNotificationDialog(
  BuildContext context,
  String title,
  String message,
  Color color,
  IconData icon, {
  VoidCallback? onOkPressed,
  Duration autoCloseDuration = const Duration(seconds: 3),
}) {
  bool alreadyClosed = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (ctx) {
      // Auto close after duration
      Future.delayed(autoCloseDuration, () {
        if (ctx.mounted && !alreadyClosed) {
          alreadyClosed = true;
          Navigator.of(ctx).pop();
          if (onOkPressed != null) onOkPressed();
        }
      });

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: kThemeGlassBase.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing Icon with concentric rings
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring 2
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      // Outer ring 1
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      // Inner glow and icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.2),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(icon, color: color, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Message
                  Text(
                    message,
                    style: TextStyle(
                      color: kTextSecondary.withOpacity(0.9),
                      height: 1.5,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCyan,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        if (!alreadyClosed) {
                          alreadyClosed = true;
                          Navigator.of(ctx).pop();
                          if (onOkPressed != null) onOkPressed();
                        }
                      },
                      child: const Text(
                        'Xong',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ).then((_) => alreadyClosed = true);
}
