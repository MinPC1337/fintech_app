import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/main/presentation/pages/transaction_success_page.dart';

class GroupWalletWithdrawPage extends StatefulWidget {
  final String walletId;

  const GroupWalletWithdrawPage({super.key, required this.walletId});

  @override
  State<GroupWalletWithdrawPage> createState() =>
      _GroupWalletWithdrawPageState();
}

class _GroupWalletWithdrawPageState extends State<GroupWalletWithdrawPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleWithdraw() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final cubit = context.read<GroupWalletCubit>();
    final success = await cubit.withdrawFromGroup(
      widget.walletId,
      amount,
      _noteController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      final state = cubit.state;
      final walletName = state is GroupWalletLoaded ? state.selectedWallet?.name ?? 'Ví nhóm' : 'Ví nhóm';

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessPage(
            amount: amount,
            receiver: 'Ví cá nhân',
            sender: walletName,
            categoryName: 'Rút tiền',
            timestamp: DateTime.now(),
            note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : 'Rút tiền từ quỹ nhóm',
            isInternal: true,
            isViewOnly: false,
            customButtonText: 'Xác nhận',
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
          'Chuyển tiền / Rút tiền',
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
                            color: kRose.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [AppGlows.rose],
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
                                'Rút tiền',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Rút quỹ nhóm về ví cá nhân',
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

              _buildLabel('Số tiền rút'),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: _inputDecoration(
                  hint: '0',
                  icon: Icons.money_off_rounded,
                  iconColor: kRose,
                  suffix: 'VNĐ',
                ),
              ),

              const SizedBox(height: 20),

              _buildLabel('Ghi chú (tùy chọn)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: kTextPrimary, fontSize: 14),
                decoration: _inputDecoration(
                  hint: 'Ví dụ: Trả tiền ăn trưa',
                  icon: Icons.note_alt_rounded,
                  iconColor: kTextSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Nút Rút
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRose,
                  disabledBackgroundColor: kRose.withValues(alpha: 0.4),
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
                            Icons.outbox_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Xác nhận rút',
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
    String? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kTextSecondary),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: kTextSecondary, fontSize: 14),
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
