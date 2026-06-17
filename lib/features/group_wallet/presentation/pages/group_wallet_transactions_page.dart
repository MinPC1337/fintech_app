import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubit/group_wallet_cubit.dart';
import '../cubit/group_wallet_state.dart';
// Copied _TransactionTile logic directly into the list item.

class GroupWalletTransactionsPage extends StatelessWidget {
  final String walletId;

  const GroupWalletTransactionsPage({super.key, required this.walletId});

  String _formatMoney(double value) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return currency.format(value).replaceAll('đ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Lịch sử giao dịch', style: TextStyle(color: kTextPrimary)),
        centerTitle: true,
      ),
      body: BlocBuilder<GroupWalletCubit, GroupWalletState>(
        builder: (context, state) {
          if (state is! GroupWalletLoaded) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }

          final walletTransactions = state.transactions.where((tx) {
            if (tx.type == 'Income') return tx.toWalletId == walletId;
            if (tx.type == 'Expense') return tx.fromWalletId == walletId;
            return false;
          }).toList();

          if (walletTransactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Không có giao dịch nào trong ví này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: walletTransactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = walletTransactions[index];
              final isExpense = tx.type == 'Expense';
              final color = isExpense ? kRose : kEmerald;
              final icon = isExpense ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
              final categoryName = isExpense ? 'Chi tiêu quỹ' : 'Nạp quỹ'; // Simplified for now. It uses categoryId in real app

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kThemeSurfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.15),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.note.isNotEmpty ? tx.note : categoryName,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(tx.timestamp),
                            style: TextStyle(
                              color: kTextSecondary.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${isExpense ? '-' : '+'}${_formatMoney(tx.amount)} đ',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
