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

class BudgetAllocationCard extends StatefulWidget {
  const BudgetAllocationCard({
    super.key,
    required this.items,
    this.isActive = true,
  });

  final List<AllocationItem> items;
  final bool isActive;

  @override
  State<BudgetAllocationCard> createState() => _BudgetAllocationCardState();
}

class _BudgetAllocationCardState extends State<BudgetAllocationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BudgetAllocationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0.0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If no items or total value is 0, we can show an empty state.
    final total = widget.items.fold<double>(0, (s, i) => s + i.value);

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
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final animValue = _animation.value;
                return Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 120,
                        // ScaleX: -1 lật ngược biểu đồ để tạo hiệu ứng vẽ ngược chiều kim đồng hồ (từ phải qua trái)
                        child: Transform.scale(
                          scaleX: -1,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 25,
                              startDegreeOffset: 270,
                              sections: [
                                ...widget.items.map((e) {
                                  return PieChartSectionData(
                                    value: e.value * animValue,
                                    color: e.color,
                                    radius: 25,
                                    showTitle: false,
                                  );
                                }),
                                if (animValue < 1.0)
                                  PieChartSectionData(
                                    value: 100 * (1 - animValue),
                                    color: Colors.transparent,
                                    radius: 25,
                                    showTitle: false,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: widget.items
                            .map(
                              (e) => _buildLegendItem(
                                e.color,
                                e.label,
                                '${(e.value * animValue).toStringAsFixed(1).replaceAll('.0', '')}%',
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
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
