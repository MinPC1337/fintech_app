import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'budget_glass_card.dart';

class WeeklySpendingCard extends StatelessWidget {
  const WeeklySpendingCard({
    super.key,
    required this.weeklySpendings,
    required this.weeklyLimit,
  });

  final List<double> weeklySpendings;
  final double weeklyLimit;

  @override
  Widget build(BuildContext context) {
    // Determine max Y for the chart (add 20% padding above highest value)
    final maxSpending = weeklySpendings.isEmpty
        ? 0.0
        : weeklySpendings.reduce((a, b) => a > b ? a : b);
    final maxY = (maxSpending > weeklyLimit ? maxSpending : weeklyLimit) * 1.2;
    // ensure maxY > 0 to avoid Division by Zero
    final safeMaxY = maxY > 0 ? maxY : 5.0;

    return BudgetGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chi tiêu theo tuần',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Tháng này',
                      style: TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Đơn vị: đồng',
            style: TextStyle(color: kTextSecondary, fontSize: 11),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: Stack(
              children: [
                BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: safeMaxY,
                    minY: 0,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: false,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 4,
                        getTooltipItem:
                            (
                              BarChartGroupData group,
                              int groupIndex,
                              BarChartRodData rod,
                              int rodIndex,
                            ) {
                              return BarTooltipItem(
                                rod.toY.toStringAsFixed(1),
                                TextStyle(
                                  color: rod.toY > 3.8 ? kRose : kTextPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            String week = '';
                            String dates = '';
                            switch (value.toInt()) {
                              case 0:
                                week = 'Tuần 1';
                                dates = '(01-07)';
                                break;
                              case 1:
                                week = 'Tuần 2';
                                dates = '(08-14)';
                                break;
                              case 2:
                                week = 'Tuần 3';
                                dates = '(15-21)';
                                break;
                              case 3:
                                week = 'Tuần 4';
                                dates = '(22-30)';
                                break;
                              default:
                                return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    week,
                                    style: const TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    dates,
                                    style: const TextStyle(
                                      color: kTextSecondary,
                                      fontSize: 9,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          reservedSize: 36,
                        ),
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: weeklyLimit,
                          color: Colors.white.withValues(alpha: 0.2),
                          strokeWidth: 1,
                          dashArray: [3, 3],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topRight,
                            padding: const EdgeInsets.only(bottom: 4),
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 9,
                            ),
                            labelResolver: (line) => line.y.toStringAsFixed(0),
                          ),
                        ),
                      ],
                    ),
                    barGroups: weeklySpendings.asMap().entries.map((entry) {
                      return _buildBarGroup(
                        entry.key,
                        entry.value,
                        entry.value > weeklyLimit,
                      );
                    }).toList(),
                  ),
                ),
                // Custom label for the dotted line on the left
                Positioned(
                  top: 0,
                  left: 0,
                  child: Text(
                    'Ngân sách/tuần: ${weeklyLimit.toStringAsFixed(0)}',
                    style: const TextStyle(color: kTextSecondary, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, bool isOver) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 24,
          gradient: LinearGradient(
            colors: isOver
                ? [kRose.withValues(alpha: 0.8), kRose.withValues(alpha: 0.5)]
                : [
                    kPurple.withValues(alpha: 0.8),
                    kElectricBlue.withValues(alpha: 0.8),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
      showingTooltipIndicators: [0],
    );
  }
}
