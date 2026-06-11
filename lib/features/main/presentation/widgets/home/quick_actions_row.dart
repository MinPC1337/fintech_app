import 'package:flutter/material.dart';

import '../../pages/send_to_user_page.dart';
import '../../pages/receive_money_page.dart';
import '../../pages/momo_deposit_page.dart';
import '../../pages/transfer_page.dart';
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none, // Để bóng/viền không bị cắt
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActionItem(
                context: context,
                icon: Icons.send_rounded,
                color: const Color(0xFF7C3AED), // Tím
                label: 'Chuyển tiền',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendToUserPage()),
                )),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                icon: Icons.qr_code_scanner_rounded,
                color: const Color(0xFF0EA5E9), // Xanh dương
                label: 'Nhận tiền',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiveMoneyPage()),
                )),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFFD946EF), // Hồng MoMo
                label: 'Nạp MoMo',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MomoDepositPage()),
                )),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                icon: Icons.send_to_mobile_rounded,
                color: const Color(0xFFF43F5E), // Đỏ / Hồng đậm
                label: 'Rút MoMo',
                onTap: () => Future.microtask(() => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransferPage()),
                )),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFFF59E0B), // Cam
                label: 'Ngân sách',
                onTap: () {
                  Future.microtask(() => MainPage.of(context)?.changeTab(1));
                },
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                icon: Icons.group_rounded,
                color: const Color(0xFF10B981), // Xanh lá
                label: 'Ví nhóm',
                onTap: () {
                  Future.microtask(() => MainPage.of(context)?.changeTab(2));
                },
              ),
            ],
          ),
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
      child: SizedBox(
        width: 72, // Đủ rộng để chữ hiển thị tốt
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, // To ra
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20), // Bo tròn mềm mại hơn
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30, // Icon to ra
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
