import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import 'expense_summary_card.dart';
import 'expense_allocation_card.dart';
import 'income_vs_expense_card.dart';
import 'ai_insight_card.dart';

class MonthlyOverviewSection extends StatefulWidget {
  final String userId;

  const MonthlyOverviewSection({super.key, required this.userId});

  @override
  State<MonthlyOverviewSection> createState() => _MonthlyOverviewSectionState();
}

class _MonthlyOverviewSectionState extends State<MonthlyOverviewSection> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tổng quan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildMonthPicker(),
          ],
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ExpenseAllocationCard(
                  userId: widget.userId,
                  month: _selectedMonth,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: IncomeVsExpenseCard(
                  userId: widget.userId,
                  month: _selectedMonth,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ExpenseSummaryCard(userId: widget.userId, month: _selectedMonth),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AiInsightCard(userId: widget.userId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: kCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _changeMonth(-1),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.chevron_left, color: kCyan, size: 18),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MM/yyyy').format(_selectedMonth),
            style: const TextStyle(
              color: kCyan,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              final now = DateTime.now();
              // Không cho phép chọn tháng tương lai
              if (_selectedMonth.year == now.year &&
                  _selectedMonth.month == now.month) {
                return;
              }
              _changeMonth(1);
            },
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                Icons.chevron_right,
                color:
                    (_selectedMonth.year == DateTime.now().year &&
                        _selectedMonth.month == DateTime.now().month)
                    ? kCyan.withValues(alpha: 0.3)
                    : kCyan,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
