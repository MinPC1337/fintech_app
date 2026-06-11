import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../widgets/budget/budget_category_list.dart' show CategoryListItem;
import '../widgets/budget/budget_glass_card.dart';
import 'add_budget_page.dart';
import 'budget_category_transactions_page.dart';

class BudgetCategoryDetailsPage extends StatefulWidget {
  const BudgetCategoryDetailsPage({super.key, required this.items});

  final List<CategoryListItem> items;

  @override
  State<BudgetCategoryDetailsPage> createState() =>
      _BudgetCategoryDetailsPageState();
}

class _BudgetCategoryDetailsPageState extends State<BudgetCategoryDetailsPage> {
  bool _isEditMode = false;

  void _navigateToEdit(CategoryListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddBudgetPage(
          walletId: item.walletId,
          category: item.category,
        ),
      ),
    );
  }

  void _navigateToTransactions(CategoryListItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetCategoryTransactionsPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết danh mục',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.items.isNotEmpty)
            IconButton(
              icon: Icon(
                _isEditMode ? Icons.check : Icons.edit,
                color: _isEditMode ? kEmerald : Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isEditMode = !_isEditMode;
                });
              },
            ),
        ],
      ),
      body: widget.items.isEmpty
          ? const Center(
              child: Text(
                'Chưa có danh mục nào được thiết lập',
                style: TextStyle(color: kTextSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: _isEditMode
                        ? () => _navigateToEdit(item)
                        : () => _navigateToTransactions(item),
                    child: _buildDetailedCategoryItem(item),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetailedCategoryItem(CategoryListItem item) {
    final barColor = item.isOverBudget ? kRose : item.iconColor;

    return BudgetGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: item.emoji != null && item.emoji!.isNotEmpty
                ? Text(item.emoji!, style: const TextStyle(fontSize: 24))
                : Icon(Icons.category, color: item.iconColor, size: 24),
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
                      item.title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        text: '${item.spent} / ',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: item.limit,
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
                            value: item.ratio,
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
                        item.percentage,
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
          if (_isEditMode) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.edit,
              color: kElectricBlue.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}
