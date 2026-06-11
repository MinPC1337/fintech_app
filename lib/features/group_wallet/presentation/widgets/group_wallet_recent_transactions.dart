import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'group_wallet_glass_card.dart';

/// Section "Giao dịch gần đây" — list of recent transactions with mock data.
class GroupWalletRecentTransactions extends StatelessWidget {
  const GroupWalletRecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: kCyan.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: kCyan.withValues(alpha: 0.9),
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Transaction list
        GroupWalletGlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              for (int i = 0; i < _mockTransactions.length; i++) ...[
                _TransactionItem(data: _mockTransactions[i]),
                if (i < _mockTransactions.length - 1)
                  Divider(
                    color: Colors.white.withValues(alpha: 0.05),
                    height: 1,
                    indent: 62,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({required this.data});

  final _MockTransaction data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.iconBgColor.withValues(alpha: 0.12),
            ),
            child: Center(
              child: Text(
                data.emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Amount + date/status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.amount,
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.dateTime,
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.status,
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Mock data ──────────────────────────────────────────
class _MockTransaction {
  final String emoji;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String amount;
  final String dateTime;
  final String status;

  const _MockTransaction({
    required this.emoji,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateTime,
    required this.status,
  });
}

const _mockTransactions = <_MockTransaction>[
  _MockTransaction(
    emoji: '🏨',
    iconBgColor: kCyan,
    title: 'Thanh toán khách sạn',
    subtitle: 'Du lịch Đà Nẵng ✈️',
    amount: '-2.800.000 đ',
    dateTime: '20/06/2026 • 10:30',
    status: 'Bạn đã trả',
  ),
  _MockTransaction(
    emoji: '⚡',
    iconBgColor: kPurple,
    title: 'Tiền điện tháng 6',
    subtitle: 'Thuê nhà 4A',
    amount: '-600.000 đ',
    dateTime: '19/06/2026 • 18:45',
    status: 'Minh đã trả',
  ),
  _MockTransaction(
    emoji: '🎂',
    iconBgColor: kRose,
    title: 'Quà sinh nhật',
    subtitle: 'Sinh nhật Minh 🎁',
    amount: '-450.000 đ',
    dateTime: '18/06/2026 • 14:20',
    status: 'Lan đã trả',
  ),
  _MockTransaction(
    emoji: '🍽️',
    iconBgColor: kEmerald,
    title: 'Ăn tối hải sản',
    subtitle: 'Du lịch Đà Nẵng ✈️',
    amount: '-1.250.000 đ',
    dateTime: '18/06/2026 • 19:30',
    status: 'Bạn đã trả',
  ),
];
