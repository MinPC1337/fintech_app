import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../main/domain/entities/debt_entity.dart';
import 'group_wallet_glass_card.dart';

/// Section "Bạn cần trả" — compact card showing real debts.
class GroupWalletDebtsCard extends StatelessWidget {
  const GroupWalletDebtsCard({
    super.key,
    required this.debts,
    required this.walletNames,
    required this.onNavigateToDebts,
  });

  final List<DebtEntity> debts;
  final Map<String, String> walletNames;
  final void Function(String) onNavigateToDebts;

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return GroupWalletGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: kEmerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '0 khoản',
                    style: TextStyle(
                      color: kEmerald,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Bạn không có khoản nợ nào cần thanh toán.',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final totalDebtAmount = debts.fold(0.0, (sum, debt) => sum + debt.amount);

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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kRose.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${debts.length} khoản',
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
            '${_formatCurrency(totalDebtAmount)} đ',
            style: TextStyle(
              color: kRose,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),

          // Debt items
          ...debts.map(
            (d) => _DebtItem(
              debt: d,
              walletName: walletNames[d.walletId] ?? d.walletId,
              onTap: () => onNavigateToDebts(d.walletId),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

class _DebtItem extends StatelessWidget {
  const _DebtItem({
    required this.debt,
    required this.walletName,
    required this.onTap,
  });

  final DebtEntity debt;
  final String walletName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formattedAmount = '${_formatCurrency(debt.amount)} đ';
    final dateStr = debt.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(debt.createdAt!)
        : '--/--/----';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCyan.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '🏠', // Fallback emoji for wallet
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    walletName,
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
                  formattedAmount,
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
                  'Tạo ngày $dateStr',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // "Trả ngay" button
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
