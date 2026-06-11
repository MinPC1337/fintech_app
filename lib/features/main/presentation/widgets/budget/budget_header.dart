import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class BudgetHeader extends StatelessWidget {
  const BudgetHeader({
    super.key,
    required this.monthYearText,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onAddBudget,
  });

  final String monthYearText;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onAddBudget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ngân sách',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý ngân sách của bạn',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            IconButton(
              onPressed: onAddBudget,
              style: IconButton.styleFrom(
                backgroundColor: kCyan.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(12),
              ),
              icon: const Icon(Icons.add_rounded, color: kCyan),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavButton(icon: Icons.arrow_back, onTap: onPrevMonth),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kElectricBlue, kCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: kElectricBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthYearText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            _NavButton(icon: Icons.arrow_forward, onTap: onNextMonth),
          ],
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF162033),
          shape: BoxShape.circle,
          border: Border.all(color: kCyan.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: kTextSecondary, size: 20),
      ),
    );
  }
}
