import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/main/domain/usecases/get_primary_wallet_stream_usecase.dart';
import 'package:fintech_app/injection_container.dart' as di;
import 'package:fintech_app/features/main/presentation/pages/transaction_success_page.dart';

class GroupWalletContributePage extends StatefulWidget {
  final String walletId;

  const GroupWalletContributePage({super.key, required this.walletId});

  @override
  State<GroupWalletContributePage> createState() =>
      _GroupWalletContributePageState();
}

class _GroupWalletContributePageState extends State<GroupWalletContributePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    getPrimaryWalletStreamUseCase = di.sl<GetPrimaryWalletStreamUseCase>();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleContribute() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final cubit = context.read<GroupWalletCubit>();
    final success = await cubit.contributeToGroup(widget.walletId, amount, _noteController.text);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    
    if (success) {
      final state = cubit.state;
      final walletName = state is GroupWalletLoaded ? state.selectedWallet?.name ?? 'Ví nhóm' : 'Ví nhóm';
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TransactionSuccessPage(
            amount: amount,
            receiver: walletName,
            sender: 'Ví cá nhân',
            categoryName: 'Nạp tiền',
            timestamp: DateTime.now(),
            note: _noteController.text.isNotEmpty ? _noteController.text : 'Nạp tiền vào quỹ nhóm',
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
          'Nạp quỹ nhóm',
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
                            color: kEmerald.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [AppGlows.emerald],
                          ),
                          child: const Text(
                            '📥',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nạp quỹ',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Đóng góp tiền vào quỹ chung của nhóm',
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
              
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) {
                  if (authState is! AuthSuccess) return const SizedBox.shrink();
                  final user = authState.user;
                  return StreamBuilder(
                    stream: getPrimaryWalletStreamUseCase.call(user.uid),
                    builder: (context, snapshot) {
                      double currentBalance = 0.0;
                      if (snapshot.hasData) {
                        snapshot.data!.fold((_) {}, (wallet) {
                          currentBalance = wallet?.balance ?? 0.0;
                        });
                      }

                      return Container(
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
                              backgroundImage: user.avatarUrl.isNotEmpty
                                  ? NetworkImage(user.avatarUrl)
                                  : null,
                              child: user.avatarUrl.isEmpty
                                  ? const Icon(Icons.person, color: kCyan)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName.isNotEmpty ? user.fullName : user.email,
                                    style: const TextStyle(
                                      color: kTextPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Số dư: ${currencyFormatter.format(currentBalance)}',
                                    style: TextStyle(
                                      color: kTextSecondary.withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: kCyan.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Ví cá nhân',
                                style: TextStyle(
                                  color: kCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              _buildLabel('Số tiền nạp'),
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
                  icon: Icons.monetization_on_rounded,
                  iconColor: kEmerald,
                  suffix: 'VNĐ',
                ),
              ),

              const SizedBox(height: 24),
              _buildLabel('Ghi chú (Tùy chọn)'),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: kTextPrimary),
                decoration: _inputDecoration(
                  hint: 'Nhập ghi chú nạp tiền',
                  icon: Icons.notes_rounded,
                  iconColor: kTextSecondary,
                ),
              ),

              const SizedBox(height: 40),

              // Nút Nạp
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleContribute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kEmerald,
                  disabledBackgroundColor: kEmerald.withValues(alpha: 0.4),
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
                            'Xác nhận nạp',
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
