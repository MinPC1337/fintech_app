import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/main/domain/entities/transaction_entity.dart';

class GroupWalletBarChart extends StatelessWidget {
  final List<TransactionEntity> transactions;

  const GroupWalletBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Nhóm dữ liệu theo 7 ngày gần nhất
    final now = DateTime.now();
    final Map<int, Map<String, double>> groupedData = {};

    for (int i = 6; i >= 0; i--) {
      groupedData[i] = {'income': 0.0, 'expense': 0.0};
    }

    for (final tx in transactions) {
      final difference = now.difference(tx.timestamp).inDays;
      if (difference >= 0 && difference < 7) {
        if (tx.type == 'Income' || tx.categoryId == 'group_contribute') {
          groupedData[difference]!['income'] = (groupedData[difference]!['income'] ?? 0) + tx.amount;
        } else if (tx.type == 'Expense' || tx.categoryId == 'group_withdraw') {
          groupedData[difference]!['expense'] = (groupedData[difference]!['expense'] ?? 0) + tx.amount;
        }
      }
    }

    // Tính giá trị maxY cho biểu đồ
    double maxData = 0;
    for (final data in groupedData.values) {
      final income = data['income']!;
      final expense = data['expense']!;
      if (income > maxData) maxData = income;
      if (expense > maxData) maxData = expense;
    }
    double maxY = maxData > 0 ? maxData * 1.2 : 100000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thu chi 7 ngày qua',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final daysAgo = 6 - value.toInt();
                        final date = now.subtract(Duration(days: daysAgo));
                        final label = DateFormat('dd/MM').format(date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: kTextSecondary.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox.shrink();

                        String text = '';
                        if (value >= 1000000000) {
                          text = '${(value / 1000000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}B';
                        } else if (value >= 1000000) {
                          text = '${(value / 1000000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}M';
                        } else if (value >= 1000) {
                          text = '${(value / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}k';
                        } else {
                          text = value.toInt().toString();
                        }
                        
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            text,
                            style: TextStyle(
                              color: kTextSecondary.withValues(alpha: 0.8),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) {
                  final indexInMap = 6 - i;
                  final income = groupedData[indexInMap]?['income'] ?? 0;
                  final expense = groupedData[indexInMap]?['expense'] ?? 0;
                  
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: income,
                        color: kEmerald,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      BarChartRodData(
                        toY: expense,
                        color: kRose,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(kEmerald, 'Thu'),
              const SizedBox(width: 24),
              _buildLegend(kRose, 'Chi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: kTextSecondary.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
