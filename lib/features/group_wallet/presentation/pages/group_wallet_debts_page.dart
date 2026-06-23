import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/group_wallet_cubit.dart';
import '../cubit/group_wallet_state.dart';
import '../../../main/domain/entities/debt_entity.dart';
import 'group_wallet_settle_debt_page.dart';

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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text('Công nợ', style: TextStyle(color: kTextPrimary)),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: kCyan,
            labelColor: kCyan,
            unselectedLabelColor: kTextSecondary,
            tabs: [
              Tab(text: 'Nợ chưa thanh toán'),
              Tab(text: 'Thanh toán nợ'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: BlocBuilder<GroupWalletCubit, GroupWalletState>(
          builder: (context, state) {
            if (state is! GroupWalletLoaded) {
              return const Center(child: CircularProgressIndicator(color: kCyan));
            }

            final wallet = state.selectedWallet?.id == walletId
                ? state.selectedWallet
                : state.wallets.firstWhere((w) => w.id == walletId);
            final isClosed = wallet?.status == 'closed';

            final allWalletDebts = state.debts
                .where((debt) => debt.walletId == walletId)
                .toList();

            // Lọc ra các tab:
            // 1. Nợ chưa thanh toán (Người khác nợ mình)
            final unpaidOwedToMe = allWalletDebts
                .where((d) => !d.isSettled && d.lenderId == currentUserId)
                .toList();
            
            // 2. Thanh toán nợ (Mình nợ người khác)
            final unpaidIOwe = allWalletDebts
                .where((d) => !d.isSettled && d.borrowerId == currentUserId)
                .toList();

            // 3. Lịch sử (Đã thanh toán)
            final settledDebts = allWalletDebts
                .where((d) => d.isSettled)
                .toList()
              ..sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));

            return TabBarView(
              children: [
                _buildDebtList(
                  context: context,
                  debts: unpaidOwedToMe,
                  currentUserId: currentUserId,
                  isClosed: isClosed,
                  state: state,
                  emptyMessage: 'Bạn không có khoản cho mượn nào chưa thanh toán.',
                ),
                _buildDebtList(
                  context: context,
                  debts: unpaidIOwe,
                  currentUserId: currentUserId,
                  isClosed: isClosed,
                  state: state,
                  emptyMessage: 'Bạn không có khoản nợ nào cần thanh toán.',
                ),
                _buildDebtList(
                  context: context,
                  debts: settledDebts,
                  currentUserId: currentUserId,
                  isClosed: isClosed,
                  state: state,
                  emptyMessage: 'Chưa có lịch sử thanh toán nào.',
                  isHistory: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDebtList({
    required BuildContext context,
    required List<DebtEntity> debts,
    required String currentUserId,
    required bool isClosed,
    required GroupWalletLoaded state,
    required String emptyMessage,
    bool isHistory = false,
  }) {
    if (debts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            emptyMessage,
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
      itemCount: debts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final debt = debts[index];
        final isLender = debt.lenderId == currentUserId;
        final otherId = isLender ? debt.borrowerId : debt.lenderId;
        final otherName = state.memberNames[otherId] ?? 'Người dùng';
        final otherAvatar = state.memberAvatars[otherId];

        VoidCallback? onSettle;
        VoidCallback? onRemind;

        if (!isHistory && !isClosed) {
          if (debt.borrowerId == currentUserId && !debt.isSettled) {
            onSettle = () {
              final cubit = context.read<GroupWalletCubit>();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: GroupWalletSettleDebtPage(
                      debt: debt,
                      lenderName: otherName,
                      lenderAvatar: otherAvatar,
                    ),
                  ),
                ),
              );
            };
          } else if (debt.lenderId == currentUserId && !debt.isSettled) {
            onRemind = () => context.read<GroupWalletCubit>().remindDebt(debt.id);
          }
        }

        return _DebtTile(
          debt: debt,
          currentUserId: currentUserId,
          formatMoney: _formatMoney,
          otherName: otherName,
          otherAvatar: otherAvatar,
          onSettle: onSettle,
          onRemind: onRemind,
          isHistory: isHistory,
        );
      },
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.currentUserId,
    required this.formatMoney,
    required this.otherName,
    this.otherAvatar,
    this.onSettle,
    this.onRemind,
    this.isHistory = false,
  });

  final DebtEntity debt;
  final String currentUserId;
  final String Function(double) formatMoney;
  final String otherName;
  final String? otherAvatar;
  final VoidCallback? onSettle;
  final VoidCallback? onRemind;
  final bool isHistory;

  @override
  Widget build(BuildContext context) {
    final isLender = debt.lenderId == currentUserId;
    
    // Determine color based on status and role
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  image: otherAvatar != null && otherAvatar!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(otherAvatar!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: otherAvatar != null && otherAvatar!.isNotEmpty
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
          if (isHistory && debt.createdAt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, color: kTextSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(debt.createdAt!),
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
