import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'budget_glass_card.dart';

class AlertItem {
  final String? emoji;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;

  AlertItem({
    this.emoji,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
  });
}

class BudgetAlertsCard extends StatefulWidget {
  const BudgetAlertsCard({super.key, required this.items});

  final List<AlertItem> items;

  @override
  State<BudgetAlertsCard> createState() => _BudgetAlertsCardState();
}

class _BudgetAlertsCardState extends State<BudgetAlertsCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayItems = _isExpanded
        ? widget.items
        : widget.items.take(4).toList();

    return BudgetGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 8,
            children: [
              const Text(
                'Cảnh báo ngân sách',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.items.length > 4)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _isExpanded ? 'Thu gọn' : 'Xem tất cả',
                      style: TextStyle(
                        color: kElectricBlue.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Chưa có cảnh báo nào',
                style: TextStyle(color: kTextSecondary),
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                children: displayItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildAlertItem(
                    emoji: item.emoji,
                    iconColor: item.iconColor,
                    title: item.title,
                    subtitle: item.subtitle,
                    badgeText: item.badgeText,
                    badgeColor: item.badgeColor,
                    isLast: index == displayItems.length - 1,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    String? emoji,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: emoji != null && emoji.isNotEmpty
                ? Text(emoji, style: const TextStyle(fontSize: 20))
                : Icon(Icons.category, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: kTextSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
