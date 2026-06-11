import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class GroupWalletHeader extends StatelessWidget {
  const GroupWalletHeader({
    super.key,
    required this.onCreateWallet,
  });

  final VoidCallback onCreateWallet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ví nhóm',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Quản lý chi tiêu chung dễ dàng',
                    style: TextStyle(
                      color: kTextSecondary.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // + Tạo ví nhóm button
            GestureDetector(
              onTap: onCreateWallet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: kCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: kCyan.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: kCyan, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      'Tạo ví nhóm',
                      style: TextStyle(
                        color: kCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
