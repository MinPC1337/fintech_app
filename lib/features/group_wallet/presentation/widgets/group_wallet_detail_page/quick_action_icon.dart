import 'package:flutter/material.dart';
import 'package:fintech_app/core/theme/app_colors.dart';

class QuickActionIcon extends StatelessWidget {
  const QuickActionIcon({
    super.key,
    required this.iconPath,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 28,
                height: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
