import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../domain/usecases/get_transactions_stream_usecase.dart';
import '../../../domain/usecases/watch_out_categories_usecase.dart';
import '../../../domain/entities/category_entity.dart';

class ExpenseSummaryCard extends StatefulWidget {
  final String userId;
  final DateTime month;

  const ExpenseSummaryCard({super.key, required this.userId, required this.month});

  @override
  State<ExpenseSummaryCard> createState() => _ExpenseSummaryCardState();
}

class _ExpenseSummaryCardState extends State<ExpenseSummaryCard> {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase;
  late final GetTransactionsStreamUseCase getTransactionsStreamUseCase;
  late final WatchOutCategoriesUseCase watchOutCategoriesUseCase;

  @override
  void initState() {
    super.initState();
    getPrimaryWalletStreamUseCase = sl<GetPrimaryWalletStreamUseCase>();
    getTransactionsStreamUseCase = sl<GetTransactionsStreamUseCase>();
    watchOutCategoriesUseCase = sl<WatchOutCategoriesUseCase>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E293B).withValues(alpha: 0.8),
            const Color(0xFF0F172A).withValues(alpha: 0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Điểm nhấn Background Glow
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kRose.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPurple.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: StreamBuilder(
              stream: getPrimaryWalletStreamUseCase.call(widget.userId),
              builder: (context, walletSnap) {
                String? primaryWalletId;
                if (walletSnap.hasData) {
                  walletSnap.data!.fold((f) => null, (w) {
                    primaryWalletId = w?.id;
                  });
                }

                return StreamBuilder<List<dynamic>>(
                  stream: getTransactionsStreamUseCase.call(widget.userId),
                  builder: (context, snapshot) {
                    return StreamBuilder<List<CategoryEntity>>(
                      stream: watchOutCategoriesUseCase.call(widget.userId, month: widget.month.month, year: widget.month.year),
                      builder: (context, budgetSnap) {
                        double totalExpense = 0.0;
                        double totalBudgetLimit = 0.0;
                        
                        if (snapshot.hasData && primaryWalletId != null) {
                          final allTransactions = snapshot.data ?? [];
                          final targetMonth = widget.month;
                          final monthlyTxs = allTransactions.where((tx) {
                            return (tx.fromWalletId == primaryWalletId ||
                                    tx.toWalletId == primaryWalletId) &&
                                tx.timestamp.month == targetMonth.month &&
                                tx.timestamp.year == targetMonth.year;
                          });

                          totalExpense = monthlyTxs
                              .where((tx) => tx.fromWalletId == primaryWalletId)
                              .fold(0.0, (sum, tx) => sum + tx.amount);
                        }

                        if (budgetSnap.hasData) {
                          totalBudgetLimit = budgetSnap.data!.fold(0.0, (sum, c) => sum + c.budgetLimit);
                        }

                        double percent = 0;
                        if (totalBudgetLimit > 0) {
                          percent = totalExpense / totalBudgetLimit;
                        } else {
                          // Nếu chưa có ngân sách, phần trăm là 0 (nếu không có chi tiêu) hoặc 100% nếu có
                          percent = totalExpense > 0 ? 1.0 : 0.0;
                        }
                        
                        if (percent > 1.0) percent = 1.0;
                        
                        final remaining = totalBudgetLimit - totalExpense;
                        final isOverBudget = remaining < 0 && totalBudgetLimit > 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: kRose.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.shopping_bag_rounded, color: kRose, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Chi tiêu tháng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${currencyFormatter.format(totalExpense).replaceAll('đ', '').trim()} đ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              totalBudgetLimit > 0 
                                  ? 'Ngân sách: ${currencyFormatter.format(totalBudgetLimit).replaceAll('đ', '').trim()} đ'
                                  : 'Chưa thiết lập ngân sách',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Progress bar
                            if (totalBudgetLimit > 0) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: percent,
                                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                                        valueColor: AlwaysStoppedAnimation<Color>(isOverBudget ? kRose : kEmerald),
                                        minHeight: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${(percent * 100).toInt()}%',
                                    style: TextStyle(
                                      color: isOverBudget ? kRose : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              
                              // Success/Warning message box
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isOverBudget 
                                      ? kRose.withValues(alpha: 0.15)
                                      : kEmerald.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isOverBudget 
                                      ? kRose.withValues(alpha: 0.3)
                                      : kEmerald.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isOverBudget ? kRose.withValues(alpha: 0.2) : kEmerald.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isOverBudget ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                                        color: isOverBudget ? kRose : kEmerald,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        isOverBudget 
                                            ? 'Bạn đã vượt ngân sách ${currencyFormatter.format(-remaining).replaceAll('đ', '').trim()} đ'
                                            : 'Ngân sách còn ${currencyFormatter.format(remaining).replaceAll('đ', '').trim()} đ',
                                        style: TextStyle(
                                          color: isOverBudget ? kRose : kEmerald,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Thông báo khi chưa có ngân sách
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Tạo danh mục ngân sách để theo dõi hạn mức chi tiêu.',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
