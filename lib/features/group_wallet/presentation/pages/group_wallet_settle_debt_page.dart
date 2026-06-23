import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';
import 'package:fintech_app/features/main/presentation/pages/transaction_success_page.dart';

class GroupWalletSettleDebtPage extends StatefulWidget {
  final DebtEntity debt;
  final String lenderName;
  final String? lenderAvatar;

  const GroupWalletSettleDebtPage({
    super.key,
    required this.debt,
    required this.lenderName,
    this.lenderAvatar,
  });

  @override
  State<GroupWalletSettleDebtPage> createState() =>
      _GroupWalletSettleDebtPageState();
}

class _GroupWalletSettleDebtPageState extends State<GroupWalletSettleDebtPage> {
  final TextEditingController _noteController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleSettle() async {
    setState(() => _isSubmitting = true);
    final cubit = context.read<GroupWalletCubit>();
    final success = await cubit.settleDebt(widget.debt.id);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessPage(
            amount: widget.debt.amount,
            receiver: widget.lenderName,
            sender: 'Ví cá nhân',
            categoryName: 'Thanh toán nợ',
            timestamp: DateTime.now(),
            note: _noteController.text.isNotEmpty
                ? _noteController.text
                : 'Thanh toán nợ nhóm',
            isInternal: true,
            isViewOnly: false,
            customButtonText: 'Hoàn tất',
            onCustomButtonPressed: (ctx) {
              Navigator.of(ctx).pop();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text(
          'Thanh toán nợ',
          style: TextStyle(color: kTextPrimary),
        ),
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero header
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
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: kCyan.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [AppGlows.cyan],
                          ),
                          child: const Text(
                            '💸',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trả nợ',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Thanh toán khoản nợ cho bạn bè',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kThemeSurfaceSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kThemeBorderDefault),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: kCyan.withValues(alpha: 0.2),
                      backgroundImage: (widget.lenderAvatar != null && widget.lenderAvatar!.isNotEmpty)
                          ? NetworkImage(widget.lenderAvatar!)
                          : null,
                      child: (widget.lenderAvatar == null || widget.lenderAvatar!.isEmpty)
                          ? const Icon(Icons.person, color: kCyan)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Người nhận',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.lenderName,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Số tiền thanh toán'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: kThemeSurfaceSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kThemeBorderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: kCyan, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currencyFormatter.format(widget.debt.amount).replaceAll('đ', '').trim(),
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      'VNĐ',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildLabel('Ghi chú (Tùy chọn)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: kTextPrimary),
                decoration: _inputDecoration(
                  hint: 'Nhập lời nhắn cho người nhận...',
                  icon: Icons.notes_rounded,
                  iconColor: kTextSecondary,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSettle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kCyan,
                  disabledBackgroundColor: kCyan.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Xác nhận thanh toán',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: kTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSecondary),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: kThemeSurfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kThemeBorderDefault),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: kThemeBorderDefault),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kCyan),
      ),
    );
  }
}
