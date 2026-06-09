import 'package:flutter/material.dart';

import '../../pages/send_to_user_page.dart';
import '../../pages/receive_money_page.dart';
import '../../pages/momo_deposit_page.dart';
import '../../pages/main_page.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thao tác nhanh',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildActionItem(
                context: context,
                icon: Icons.send_rounded,
                color: const Color(0xFF7C3AED), // Tím
                label: 'Chuyển tiền',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendToUserPage()),
                )),
              ),
            ),
            Expanded(
              child: _buildActionItem(
                context: context,
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF0EA5E9), // Xanh dương
                label: 'Nhận tiền',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiveMoneyPage()),
                )),
              ),
            ),
            Expanded(
              child: _buildActionItem(
                context: context,
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFFD946EF), // Hồng MoMo
                label: 'Nạp MoMo',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MomoDepositPage()),
                )),
              ),
            ),
            Expanded(
              child: _buildActionItem(
                context: context,
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFFF59E0B), // Cam
                label: 'Ngân sách',
                onTap: () {
                  Future.microtask(() => MainPage.of(context)?.changeTab(1));
                },
              ),
            ),
            Expanded(
              child: _buildActionItem(
                context: context,
                icon: Icons.group_rounded,
                color: const Color(0xFF10B981), // Xanh lá
                label: 'Ví nhóm',
                onTap: () {
                  Future.microtask(() => MainPage.of(context)?.changeTab(2));
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, // Nhỏ hơn một chút để chứa được 5 items
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16), // Squircle
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
