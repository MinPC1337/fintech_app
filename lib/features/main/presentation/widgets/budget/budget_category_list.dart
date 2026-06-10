import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class CategoryListItem {
  final String? emoji;
  final Color iconColor;
  final String title;
  final String spent;
  final String limit;
  final String percentage;
  final double ratio;
  final bool isOverBudget;
  final String categoryId;

  CategoryListItem({
    this.emoji,
    required this.iconColor,
    required this.title,
    required this.spent,
    required this.limit,
    required this.percentage,
    required this.ratio,
    required this.isOverBudget,
    required this.categoryId,
  });
}

class BudgetCategoryList extends StatelessWidget {
  const BudgetCategoryList({super.key, required this.items});

  final List<CategoryListItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ngân sách theo danh mục',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Xem tất cả',
              style: TextStyle(
                color: kElectricBlue.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Chưa có danh mục nào được thiết lập',
                style: TextStyle(color: kTextSecondary),
              ),
            ),
          )
        else
          ...items.map((item) {
            return _buildCategoryItem(
              emoji: item.emoji,
              iconColor: item.iconColor,
              title: item.title,
              spent: item.spent,
              limit: item.limit,
              percentage: item.percentage,
              ratio: item.ratio,
              isOverBudget: item.isOverBudget,
            );
          }),
      ],
    );
  }

  Widget _buildCategoryItem({
    String? emoji,
    required Color iconColor,
    required String title,
    required String spent,
    required String limit,
    required String percentage,
    required double ratio,
    bool isOverBudget = false,
  }) {
    final barColor = isOverBudget ? kRose : iconColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131B2A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: emoji != null && emoji.isNotEmpty
                ? Text(emoji, style: const TextStyle(fontSize: 24))
                : Icon(Icons.category, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '$spent / ',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: limit,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 6,
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.1,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        percentage,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: barColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right,
            color: kTextSecondary.withValues(alpha: 0.5),
            size: 20,
          ),
        ],
      ),
    );
  }
}
