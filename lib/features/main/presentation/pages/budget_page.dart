import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/emoji_mapping.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/category_entity.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/budget_state.dart';
import '../widgets/budget/budget_header.dart';
import '../widgets/budget/budget_summary_card.dart';
import '../widgets/budget/budget_allocation_card.dart';
import '../widgets/budget/weekly_spending_card.dart';
import '../widgets/budget/budget_category_list.dart';
import 'add_budget_page.dart';

String _formatBudgetMoney(double value) {
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  return currency.format(value).replaceAll('đ', '').trim();
}

String _budgetCategoryEmoji(CategoryEntity c) {
  if (c.emoji != null) {
    return c.emoji!;
  }
  return getEmojiForCategoryName(c.name);
}

void _navigateToBudgetForm(
  BuildContext context, {
  required String walletId,
  CategoryEntity? existing,
}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddBudgetPage(walletId: walletId, category: existing),
    ),
  );
}

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key, this.isActive = true});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Text(
                  'Cần đăng nhập để xem ngân sách',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }
        return BlocProvider(
          key: ValueKey(authState.user.uid),
          create: (_) => di.sl<BudgetCubit>()..start(authState.user.uid),
          child: _BudgetScaffold(isActive: isActive),
        );
      },
    );
  }
}

class _BudgetScaffold extends StatelessWidget {
  const _BudgetScaffold({this.isActive = true});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetCubit, BudgetState>(
      listenWhen: (prev, curr) {
        if (curr is! BudgetLoaded) return false;
        final msg = curr.errorMessage;
        if (msg == null || msg.isEmpty) return false;
        if (prev is BudgetLoaded && prev.errorMessage == msg) return false;
        return true;
      },
      listener: (context, state) {
        final s = state as BudgetLoaded;
        final msg = s.errorMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
          context.read<BudgetCubit>().dismissError();
        }
      },
      builder: (context, state) {
        if (state is BudgetInitial || state is BudgetLoading) {
          return const Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(child: CircularProgressIndicator(color: kCyan)),
            ),
          );
        }
        if (state is BudgetNoWallet) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Chưa có ví cá nhân. Tạo ví để dùng ngân sách.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextSecondary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (state is BudgetFailure) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kRose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          final auth = context.read<AuthCubit>().state;
                          if (auth is AuthSuccess) {
                            context.read<BudgetCubit>().start(auth.user.uid);
                          }
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        if (state is! BudgetLoaded) {
          return const Scaffold(
            backgroundColor: kBgColor,
            body: SizedBox.shrink(),
          );
        }

        final loaded = state;

        // Empty state khi chưa có danh mục ngân sách nào
        if (loaded.items.isEmpty) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: kCyan.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: kCyan.withValues(alpha: 0.2)),
                        ),
                        child: const Text('📊', style: TextStyle(fontSize: 48)),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Chưa có ngân sách',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tạo danh mục ngân sách để theo dõi\nchi tiêu và đạt mục tiêu tài chính.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kTextSecondary.withValues(alpha: 0.85),
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => _navigateToBudgetForm(
                          context,
                          walletId: loaded.walletId,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kCyan, kPurple],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: kCyan.withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tạo ngân sách đầu tiên',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final totalLimit = loaded.totalLimit;
        final totalSpent = loaded.totalSpent;
        final remaining = (totalLimit - totalSpent)
            .clamp(0, double.infinity)
            .toDouble();
        final ratio = totalLimit > 0
            ? (totalSpent / totalLimit).clamp(0, 1).toDouble()
            : 0.0;

        final now = DateTime.now();
        int remainingDays = 0;
        if (loaded.month.year == now.year && loaded.month.month == now.month) {
          final lastDay = DateTime(now.year, now.month + 1, 0).day;
          remainingDays = lastDay - now.day;
        } else if (loaded.month.isAfter(now)) {
          remainingDays = DateTime(
            loaded.month.year,
            loaded.month.month + 1,
            0,
          ).day;
        }

        final List<Color> palette = [
          const Color(0xFFF59E0B),
          kPurple,
          kElectricBlue,
          kEmerald,
          kRose,
          Colors.cyan,
          Colors.pink,
          Colors.teal,
        ];

        final allocationItems = <AllocationItem>[];
        final categoryItems = <CategoryListItem>[];

        for (int i = 0; i < loaded.items.length; i++) {
          final item = loaded.items[i];
          final color = palette[i % palette.length];
          final spent = item.spentThisMonth;
          final limit = item.budgetLimit;
          final r = limit > 0 ? spent / limit : 0.0;
          final isOver = spent > limit;
          final percentage = '${(r * 100).toInt()}%';

          // Allocation
          if (spent > 0) {
            allocationItems.add(
              AllocationItem(
                label: item.category.name,
                value: spent,
                color: color,
              ),
            );
          }



          // Category List
          categoryItems.add(
            CategoryListItem(
              emoji: _budgetCategoryEmoji(item.category),
              iconColor: color,
              title: item.category.name,
              spent: _formatBudgetMoney(spent),
              limit: '${_formatBudgetMoney(limit)} đ',
              percentage: percentage,
              ratio: r.clamp(0.0, 1.0),
              isOverBudget: isOver,
              categoryId: item.category.id,
              category: item.category,
              walletId: loaded.walletId,
              transactions: loaded.transactions
                  .where((t) => t.categoryId == item.category.id)
                  .toList(),
            ),
          );
        }

        // Convert allocation absolute values to percentages
        final totalAllocation = allocationItems.fold<double>(
          0,
          (s, i) => s + i.value,
        );
        final finalAllocationItems = allocationItems.map((e) {
          return AllocationItem(
            label: e.label,
            value: totalAllocation > 0
                ? (e.value / totalAllocation * 100)
                : 0.0,
            color: e.color,
          );
        }).toList();

        return Scaffold(
          backgroundColor: kBgColor,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BudgetHeader(
                    monthYearText:
                        'Tháng ${DateFormat('MM/yyyy').format(loaded.month)}',
                    onPrevMonth: () =>
                        context.read<BudgetCubit>().changeMonth(-1),
                    onNextMonth: () =>
                        context.read<BudgetCubit>().changeMonth(1),
                    onAddBudget: () => _navigateToBudgetForm(
                      context,
                      walletId: loaded.walletId,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BudgetSummaryCard(
                    totalBudget: _formatBudgetMoney(totalLimit),
                    spentAmount: _formatBudgetMoney(totalSpent),
                    remainingAmount: _formatBudgetMoney(remaining),
                    usagePercentage: ratio,
                    remainingDays: remainingDays,
                    isActive: isActive,
                  ),
                  const SizedBox(height: 24),
                  BudgetCategoryList(items: categoryItems),
                  const SizedBox(height: 24),
                  BudgetAllocationCard(
                    items: finalAllocationItems,
                    isActive: isActive,
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: double.infinity,
                        child: WeeklySpendingCard(
                          weeklySpendings: loaded.weeklySpendings,
                          weeklyLimit: totalLimit / 4,
                          isActive: isActive,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
