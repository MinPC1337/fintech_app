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
                iconPath: 'assets/icon_quickrow/money.png',
                color: const Color(0xFF7C3AED), // Tím
                label: 'Chuyển tiền',
                onTap: () => Future.microtask(
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SendToUserPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                iconPath: 'assets/icon_quickrow/qr-scan.png',
                color: const Color(0xFF0EA5E9), // Xanh dương
                label: 'Nhận tiền',
                onTap: () => Future.microtask(
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReceiveMoneyPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                iconPath: 'assets/icon_quickrow/money_frmm.png',
                color: const Color(0xFFD946EF), // Hồng MoMo
                label: 'Nạp Tiền',
                onTap: () => Future.microtask(
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MomoDepositPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                iconPath: 'assets/icon_quickrow/spending.png',
                color: const Color(0xFFF43F5E), // Đỏ / Hồng đậm
                label: 'Rút Tiền',
                onTap: () => Future.microtask(
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransferPage()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                iconPath: 'assets/icon_quickrow/budget.png',
                color: const Color(0xFFF59E0B), // Cam
                label: 'Ngân sách',
                onTap: () {
                  Future.microtask(() => MainPage.of(context)?.changeTab(1));
                },
              ),
              const SizedBox(width: 16),
              _buildActionItem(
                context: context,
                iconPath: 'assets/icon_quickrow/group.png',
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
    required String iconPath,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return _QuickActionItem(
      iconPath: iconPath,
      color: color,
      label: label,
      onTap: onTap,
    );
  }
}

// StatefulWidget riêng để có AnimatedScale feedback khi tap
class _QuickActionItem extends StatefulWidget {
  final String iconPath;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.iconPath,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  State<_QuickActionItem> createState() => _QuickActionItemState();
}

class _QuickActionItemState extends State<_QuickActionItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _isPressed ? 0.88 : 1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha: _isPressed ? 0.25 : 0.15,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.color.withValues(
                      alpha: _isPressed ? 0.5 : 0.3,
                    ),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Image.asset(widget.iconPath, width: 32, height: 32),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.label,
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
