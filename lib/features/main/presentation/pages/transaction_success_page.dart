import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import 'main_page.dart';

class TransactionSuccessPage extends StatelessWidget {
  final double amount;
  final String receiver;
  final String sender; // Nguồn tiền
  final String categoryName;
  final DateTime timestamp;
  final String note;
  final bool isInternal;
  final bool isViewOnly;

  const TransactionSuccessPage({
    super.key,
    required this.amount,
    required this.receiver,
    required this.sender,
    required this.categoryName,
    required this.timestamp,
    required this.note,
    this.isInternal = true,
    this.isViewOnly = false,
  });

  String get _displayCategoryName {
    // Chuyển đổi các ID hệ thống sang tên hiển thị thân thiện
    switch (categoryName) {
      case 'deposit':
        return 'Nạp tiền';
      case 'internal_transfer':
        return 'Nhận tiền nội bộ';
      default:
        return categoryName;
    }
  }

  String _formatCurrency(double value) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'VNĐ');
    return currency.format(value);
  }

  String _formatDate(DateTime date) {
    return DateFormat('HH:mm - dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: isViewOnly
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: kTextPrimary),
              title: const Text(
                'Chi tiết giao dịch',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isViewOnly) const Spacer(),

              // Success Icon & Amount
              if (!isViewOnly)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: kEmerald.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: kEmerald,
                      size: 80,
                    ),
                  ),
                ),
              if (!isViewOnly) const SizedBox(height: 24),
              if (!isViewOnly)
                const Text(
                  'Giao dịch thành công!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kEmerald,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                _formatCurrency(amount),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 40),

              // Receipt Card
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: kThemeGlassBase,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: kThemeBorderDefault),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          'Thời gian',
                          _formatDate(timestamp),
                          Icons.access_time_rounded,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: kBorder, height: 1),
                        ),
                        _buildDetailRow(
                          'Nguồn tiền',
                          sender,
                          Icons.login_rounded,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: kBorder, height: 1),
                        ),
                        _buildDetailRow(
                          'Tài khoản nhận',
                          receiver,
                          Icons.account_balance_wallet_rounded,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: kBorder, height: 1),
                        ),
                        _buildDetailRow(
                          'Danh mục',
                          _displayCategoryName,
                          Icons.category_rounded,
                        ),
                        if (note.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(color: kBorder, height: 1),
                          ),
                          _buildDetailRow('Ghi chú', note, Icons.notes_rounded),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              if (!isViewOnly) const Spacer(),

              // Action Buttons
              if (!isViewOnly)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCyan,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (!isViewOnly) const SizedBox(height: 16),
              if (!isViewOnly)
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: kBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Thực hiện giao dịch khác',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kTextSecondary, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: kTextSecondary, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
