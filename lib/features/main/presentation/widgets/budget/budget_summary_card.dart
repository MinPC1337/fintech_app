import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class BudgetSummaryCard extends StatefulWidget {
  const BudgetSummaryCard({
    super.key,
    required this.totalBudget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.usagePercentage,
    required this.remainingDays,
    this.isActive = true,
  });

  final String totalBudget;
  final String spentAmount;
  final String remainingAmount;
  final double usagePercentage; // e.g. 0.75 for 75%
  final int remainingDays;
  final bool isActive;

  @override
  State<BudgetSummaryCard> createState() => _BudgetSummaryCardState();
}

class _BudgetSummaryCardState extends State<BudgetSummaryCard>
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
    _animation = Tween<double>(begin: 0, end: widget.usagePercentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void didUpdateWidget(BudgetSummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    bool shouldAnimate = false;
    
    // Animate when page becomes active
    if (widget.isActive && !oldWidget.isActive) {
      shouldAnimate = true;
    } 
    // Animate when data changes
    else if (oldWidget.usagePercentage != widget.usagePercentage ||
        oldWidget.totalBudget != widget.totalBudget) {
      shouldAnimate = true;
    }

    if (shouldAnimate) {
      _animation = Tween<double>(begin: 0, end: widget.usagePercentage).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      // Optional: reset when inactive so it's ready for the next active state
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _progressColor {
    if (widget.usagePercentage < 0.7) return kEmerald; // Green
    if (widget.usagePercentage < 0.9) return const Color(0xFFF59E0B); // Yellow
    return kRose; // Red
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep vibrant blue
            Color(0xFF0F172A), // Dark slate
          ],
        ),
        border: Border.all(
          color: kCyan.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: kCyan.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ngân sách tháng',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          widget.totalBudget,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4, left: 4),
                          child: Text(
                            'đ',
                            style: TextStyle(
                              color: kTextPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tổng ngân sách',
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          final value = _animation.value;
                          final safeValue = value.clamp(0.0, 1.0);
                          return PieChart(
                            PieChartData(
                              sectionsSpace: 0,
                              centerSpaceRadius: 35,
                              startDegreeOffset: 270,
                              sections: [
                                PieChartSectionData(
                                  value: safeValue,
                                  color: _progressColor,
                                  radius: 12,
                                  showTitle: false,
                                ),
                                PieChartSectionData(
                                  value: (1 - safeValue),
                                  color: Colors.white.withValues(alpha: 0.05),
                                  radius: 12,
                                  showTitle: false,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              final value = _animation.value;
                              return Text(
                                '${(value * 100).toInt()}%',
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const Text(
                            'Đã sử dụng',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 28,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      final value = _animation.value;
                      final safeValue = value.clamp(0.0, 1.0);
                      final spentWidth = constraints.maxWidth * safeValue;
                      final remainingWidth = constraints.maxWidth - spentWidth;
                      
                      return Row(
                        children: [
                          // Spent part (Red)
                          Container(
                            width: spentWidth,
                            color: kRose,
                            alignment: Alignment.center,
                            child: safeValue > 0.15
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${widget.spentAmount} đ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                          // Remaining part (Green)
                          Container(
                            width: remainingWidth,
                            color: kEmerald,
                            alignment: Alignment.center,
                            child: (1 - safeValue) > 0.15
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '${widget.remainingAmount} đ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Còn ${widget.remainingDays} ngày trong tháng',
            style: const TextStyle(color: kTextSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
