import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/group_wallet_cubit.dart';
import '../cubit/group_wallet_state.dart';
import '../../../main/domain/entities/debt_entity.dart';

class GroupWalletDebtsPage extends StatelessWidget {
  final String walletId;

  const GroupWalletDebtsPage({super.key, required this.walletId});

  String _formatMoney(double value) {
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return currency.format(value).replaceAll('đ', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState is AuthSuccess ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Công nợ', style: TextStyle(color: kTextPrimary)),
        centerTitle: true,
      ),
      body: BlocBuilder<GroupWalletCubit, GroupWalletState>(
        builder: (context, state) {
          if (state is! GroupWalletLoaded) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }

          final walletDebts = state.debts
              .where((debt) => debt.walletId == walletId)
              .toList();

          if (walletDebts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Không có công nợ nào trong ví này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.8),
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: walletDebts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final debt = walletDebts[index];
              return _DebtTile(
                debt: debt,
                currentUserId: currentUserId,
                formatMoney: _formatMoney,
                memberNames: state.memberNames,
                memberAvatars: state.memberAvatars,
                onSettle: debt.borrowerId == currentUserId && !debt.isSettled
                    ? () => context.read<GroupWalletCubit>().settleDebt(debt.id)
                    : null,
                onRemind: debt.lenderId == currentUserId && !debt.isSettled
                    ? () => context.read<GroupWalletCubit>().remindDebt(debt.id)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.currentUserId,
    required this.formatMoney,
    required this.memberNames,
    required this.memberAvatars,
    this.onSettle,
    this.onRemind,
  });

  final DebtEntity debt;
  final String currentUserId;
  final String Function(double) formatMoney;
  final Map<String, String> memberNames;
  final Map<String, String> memberAvatars;
  final VoidCallback? onSettle;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final isLender = debt.lenderId == currentUserId;
    final otherId = isLender ? debt.borrowerId : debt.lenderId;
    final otherName = memberNames[otherId] ?? 'Người dùng';
    final otherAvatar = memberAvatars[otherId];

    final color = debt.isSettled
        ? kTextSecondary
        : isLender
        ? kEmerald
        : kRose;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                  image: otherAvatar != null && otherAvatar.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(otherAvatar),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: otherAvatar != null && otherAvatar.isNotEmpty
                    ? null
                    : Icon(
                        isLender
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: color,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 14,
                        ),
                        children: [
                          if (isLender) ...[
                            TextSpan(
                              text: otherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' nợ bạn'),
                          ] else ...[
                            const TextSpan(text: 'Bạn nợ '),
                            TextSpan(
                              text: otherName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      debt.isSettled ? 'Đã thanh toán' : 'Chưa thanh toán',
                      style: TextStyle(
                        color: debt.isSettled ? kTextSecondary : color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${formatMoney(debt.amount)} đ',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (!debt.isSettled && (onSettle != null || onRemind != null)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSettle ?? onRemind,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onSettle != null
                      ? kCyan
                      : kThemeSurfaceSecondary,
                  foregroundColor: onSettle != null ? Colors.white : kCyan,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: onSettle != null ? Colors.transparent : kCyan,
                    ),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  onSettle != null ? 'Thanh toán ngay' : 'Nhắc nhở',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
