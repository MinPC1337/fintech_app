import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../pages/budget_category_details_page.dart';

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
  final CategoryEntity category;
  final String walletId;
  final List<TransactionEntity> transactions;

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
    required this.category,
    required this.walletId,
    required this.transactions,
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
            if (items.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BudgetCategoryDetailsPage(items: items),
                    ),
                  );
                },
                child: Text(
                  'Xem tất cả',
                  style: TextStyle(
                    color: kElectricBlue.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: item.iconColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: item.emoji != null && item.emoji!.isNotEmpty
                            ? Text(
                                item.emoji!,
                                style: const TextStyle(fontSize: 24),
                              )
                            : Icon(
                                Icons.category,
                                color: item.iconColor,
                                size: 24,
                              ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: 70,
                        child: Text(
                          item.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
