import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'budget_glass_card.dart';

class AllocationItem {
  final String label;
  final double value; // e.g. 27 for 27%
  final Color color;

  AllocationItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class BudgetAllocationCard extends StatelessWidget {
  const BudgetAllocationCard({super.key, required this.items});

  final List<AllocationItem> items;

  @override
  Widget build(BuildContext context) {
    // If no items or total value is 0, we can show an empty state.
    final total = items.fold<double>(0, (s, i) => s + i.value);

    return BudgetGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân bổ ngân sách',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (total == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Chưa có dữ liệu phân bổ',
                  style: TextStyle(color: kTextSecondary),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 25,
                        startDegreeOffset: 180,
                        sections: items.map((e) {
                          return PieChartSectionData(
                            value: e.value,
                            color: e.color,
                            radius: 25,
                            showTitle: false,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: items
                        .map(
                          (e) => _buildLegendItem(
                            e.color,
                            e.label,
                            '${e.value.toStringAsFixed(1).replaceAll('.0', '')}%',
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: kTextPrimary, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
