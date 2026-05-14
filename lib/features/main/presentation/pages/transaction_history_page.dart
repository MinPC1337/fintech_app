import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_transactions_stream_usecase.dart';
import 'transaction_success_page.dart';

class TransactionHistoryPage extends StatelessWidget {
  final String userId;

  const TransactionHistoryPage({super.key, required this.userId});

  String _formatCategory(String categoryId) {
    // Basic formatting for known system categories if name is not available
    switch (categoryId) {
      case 'deposit':
        return 'Nạp tiền';
      case 'internal_transfer':
        return 'Chuyển tiền nội bộ';
      case 'transfer':
        return 'Rút tiền';
      default:
        // Attempt to format generic string by capitalizing
        if (categoryId.isEmpty) return 'Chưa phân loại';
        return categoryId.replaceAll('_', ' ').replaceFirstMapped(
            RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final getTransactionsUseCase = sl<GetTransactionsStreamUseCase>();

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        title: const Text(
          'Lịch sử giao dịch',
          style: TextStyle(color: kTextPrimary),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: getTransactionsUseCase.call(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: kRose),
              ),
            );
          }

          final allTransactions = snapshot.data ?? [];
          if (allTransactions.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có giao dịch nào.',
                style: TextStyle(color: kTextSecondary),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: allTransactions.length,
            itemBuilder: (context, index) {
              final tx = allTransactions[index];

              final timeDisplay = DateFormat('dd/MM/yyyy HH:mm').format(tx.timestamp);
              final isIncome = tx.type == 'Income';
              final sign = isIncome ? '+' : '-';
              final color = isIncome ? kEmerald : kRose;
              final icon = isIncome ? Icons.south_west_rounded : Icons.north_east_rounded;
              final title = tx.note.isNotEmpty
                  ? tx.note
                  : (isIncome ? 'Nhận tiền' : 'Chuyển tiền');

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionSuccessPage(
                        amount: tx.amount,
                        receiver: isIncome
                            ? (tx.senderId ?? 'Ví MoMo')
                            : (tx.receiverId ?? 'Hệ thống'),
                        categoryName: _formatCategory(tx.categoryId),
                        timestamp: tx.timestamp,
                        note: tx.note,
                        isInternal: true, // We don't have exact context here, default to true or infer
                        isViewOnly: true,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kThemeSurfaceSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(-4, 0),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: kTextPrimary.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeDisplay,
                              style: const TextStyle(
                                color: kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$sign${currencyFormatter.format(tx.amount).replaceAll('đ', '').trim()}',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
