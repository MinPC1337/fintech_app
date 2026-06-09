import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../injection_container.dart';
import '../../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../domain/usecases/get_transactions_stream_usecase.dart';
import '../../../domain/usecases/watch_out_categories_usecase.dart';
import '../../../domain/entities/category_entity.dart';

class ExpenseAllocationCard extends StatefulWidget {
  final String userId;
  final DateTime month;

  const ExpenseAllocationCard({super.key, required this.userId, required this.month});

  @override
  State<ExpenseAllocationCard> createState() => _ExpenseAllocationCardState();
}

class _ExpenseAllocationCardState extends State<ExpenseAllocationCard> {
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

  // Predefined colors for charts
  final List<Color> _chartColors = [
    const Color(0xFFF59E0B), // Orange
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEF4444), // Red
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: StreamBuilder(
        stream: getPrimaryWalletStreamUseCase.call(widget.userId),
        builder: (context, walletSnap) {
          String? primaryWalletId;
          if (walletSnap.hasData) {
            walletSnap.data!.fold((f) => null, (w) {
              primaryWalletId = w?.id;
            });
          }

          return StreamBuilder<List<CategoryEntity>>(
            stream: watchOutCategoriesUseCase.call(widget.userId, month: widget.month.month, year: widget.month.year),
            builder: (context, budgetSnap) {
              final categories = budgetSnap.data ?? [];
              final categoryMap = {for (var c in categories) c.id: c};

              return StreamBuilder<List<dynamic>>(
                stream: getTransactionsStreamUseCase.call(widget.userId),
                builder: (context, snapshot) {
                  Map<String, double> categorySums = {};
                  double totalExpense = 0.0;

                  if (snapshot.hasData && primaryWalletId != null) {
                    final allTransactions = snapshot.data ?? [];
                    final targetMonth = widget.month;
                    final monthlyTxs = allTransactions.where((tx) {
                      return tx.fromWalletId == primaryWalletId &&
                          tx.timestamp.month == targetMonth.month &&
                          tx.timestamp.year == targetMonth.year;
                    });

                    for (var tx in monthlyTxs) {
                      totalExpense += tx.amount;
                      final cid = tx.categoryId;
                      categorySums[cid] = (categorySums[cid] ?? 0.0) + tx.amount;
                    }
                  }

                  // Sort by amount descending
                  var sortedEntries = categorySums.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  // Keep top 4, group rest into "other"
                  Map<String, double> finalSums = {};
                  double otherSum = 0.0;
                  
                  for (int i = 0; i < sortedEntries.length; i++) {
                    if (i < 4) {
                      finalSums[sortedEntries[i].key] = sortedEntries[i].value;
                    } else {
                      otherSum += sortedEntries[i].value;
                    }
                  }
                  
                  if (otherSum > 0) {
                    finalSums['other_grouped'] = otherSum;
                  }

                  List<PieChartSectionData> sections = [];
                  List<Widget> legends = [];
                  int colorIndex = 0;

                  finalSums.forEach((key, value) {
                    if (value <= 0) return;
                    
                    final percent = totalExpense > 0 ? (value / totalExpense * 100) : 0;
                    final color = key == 'other_grouped' 
                        ? const Color(0xFF6B7280) // Grey for other
                        : _chartColors[colorIndex % _chartColors.length];
                    
                    if (key != 'other_grouped') colorIndex++;

                    String name = "Chưa rõ";
                    if (key == 'other_grouped') {
                      name = "Khác";
                    } else if (categoryMap.containsKey(key)) {
                      name = categoryMap[key]!.name;
                    }

                    sections.add(PieChartSectionData(
                      color: color,
                      value: value,
                      title: '',
                      radius: 10,
                    ));

                    legends.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 80),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${percent.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phân bổ chi tiêu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: totalExpense == 0 
                          ? const Center(child: Text("Không có giao dịch", style: TextStyle(color: Colors.white54, fontSize: 9), textAlign: TextAlign.center))
                          : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                  sections: sections,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    totalExpense > 1000000 
                                        ? '${(totalExpense / 1000000).toStringAsFixed(1)}M'
                                        : '${(totalExpense / 1000).toStringAsFixed(0)}K',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Tổng chi',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: legends,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
