import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'group_wallet_glass_card.dart';

/// Section "Bạn cần trả" — compact card showing debts.
/// Designed to be placed side-by-side with MembersCard.
class GroupWalletDebtsCard extends StatelessWidget {
  const GroupWalletDebtsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GroupWalletGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Bạn cần trả',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '2 khoản',
                  style: TextStyle(
                    color: kRose,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: kCyan.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: kCyan.withValues(alpha: 0.8),
                  size: 10,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Total
          const Text(
            'Tổng số tiền',
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '2.450.000 đ',
            style: TextStyle(
              color: kRose,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Debt items
          ..._mockDebts.map((d) => _DebtItem(data: d)),
        ],
      ),
    );
  }
}

class _DebtItem extends StatelessWidget {
  const _DebtItem({required this.data});

  final _MockDebt data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data.emoji,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                data.amount,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 22),
              Text(
                'Hạn ${data.deadline}',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // "Trả ngay" button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Trả ngay',
                  style: TextStyle(
                    color: kRose,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
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
class _MockDebt {
  final String emoji;
  final String name;
  final String amount;
  final String deadline;

  const _MockDebt({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.deadline,
  });
}

const _mockDebts = <_MockDebt>[
  _MockDebt(
    emoji: '🏠',
    name: 'Thuê nhà 4A',
    amount: '1.200.000 đ',
    deadline: '25/06/2026',
  ),
  _MockDebt(
    emoji: '✈️',
    name: 'Du lịch Đà Nẵng',
    amount: '1.250.000 đ',
    deadline: '28/06/2026',
  ),
];
