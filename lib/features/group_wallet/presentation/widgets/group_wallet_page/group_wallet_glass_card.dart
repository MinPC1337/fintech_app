import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class GroupWalletGlassCard extends StatelessWidget {
  const GroupWalletGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.accentColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? kCyan;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E284A), Color(0xFF11182B)],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: child,
    );
  }
}
