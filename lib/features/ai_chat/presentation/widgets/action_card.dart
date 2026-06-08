import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/ai_action.dart';

class ActionCard extends StatefulWidget {
  final AIAction action;
  final VoidCallback onExecute;

  const ActionCard({
    super.key,
    required this.action,
    required this.onExecute,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _isExecuted = false;

  @override
  Widget build(BuildContext context) {
    if (widget.action.type == AIActionType.none) return const SizedBox.shrink();

    String title = 'Thực thi hành động';
    IconData icon = Icons.play_circle_fill_rounded;
    Color color = kCyan;

    switch (widget.action.type) {
      case AIActionType.openDeposit:
        title = 'Nạp tiền ngay';
        icon = Icons.account_balance_wallet;
        color = kEmerald;
        break;
      case AIActionType.openTransfer:
        title = 'Rút tiền';
        icon = Icons.arrow_upward;
        color = kRose;
        break;
      case AIActionType.openSendMoney:
        title = 'Chuyển tiền';
        icon = Icons.send;
        color = kPurple;
        break;
      case AIActionType.openBudget:
        title = 'Xem ngân sách';
        icon = Icons.pie_chart;
        break;
      case AIActionType.openGroupWallet:
        title = 'Xem ví nhóm';
        icon = Icons.group;
        break;
      case AIActionType.openSettings:
        title = 'Mở Cài đặt';
        icon = Icons.settings;
        break;
      case AIActionType.openNotifications:
        title = 'Xem Thông báo';
        icon = Icons.notifications;
        break;
      case AIActionType.openTransactionHistory:
        title = 'Lịch sử giao dịch';
        icon = Icons.history;
        break;
      default:
        break;
    }

    // Nếu đã thực hiện → hiển thị trạng thái "đã mở"
    if (_isExecuted) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: kThemeSurfaceSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kThemeBorderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: kTextSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Đã mở: $title',
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() => _isExecuted = true);
        widget.onExecute();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, color: color, size: 12),
          ],
        ),
      ),
    );
  }
}
