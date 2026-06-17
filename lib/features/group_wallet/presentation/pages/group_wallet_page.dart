import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/injection_container.dart' as di;
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/pages/group_wallet_detail_page.dart';
import 'package:fintech_app/features/group_wallet/presentation/pages/pending_invitations_page.dart';
import 'package:fintech_app/features/group_wallet/presentation/pages/create_group_wallet_page.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/core/utils/dialog_utils.dart';

import '../widgets/group_wallet_header.dart';
import '../widgets/group_wallet_card_carousel.dart';
import '../widgets/group_wallet_overview_stats.dart';
import '../widgets/group_wallet_debts_card.dart';

class GroupWalletPage extends StatelessWidget {
  const GroupWalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Text(
                  'Đăng nhập để xem ví nhóm',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return BlocProvider(
          key: ValueKey(authState.user.uid),
          create: (_) => di.sl<GroupWalletCubit>()..start(authState.user.uid),
          child: const _GroupWalletView(),
        );
      },
    );
  }
}

class _GroupWalletView extends StatelessWidget {
  const _GroupWalletView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupWalletCubit, GroupWalletState>(
      listenWhen: (previous, current) {
        if (current is GroupWalletLoaded && current.message != null) {
          if (previous is! GroupWalletLoaded) return true;
          return current.message != previous.message;
        }
        return false;
      },
      listener: (context, state) {
        if (state is GroupWalletLoaded && state.message != null) {
          // Chỉ hiển thị thông báo nếu trang này đang ở trên cùng (không bị Detail che)
          if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

          showNotificationDialog(
            context,
            'Thông báo',
            state.message!,
            kCyan,
            Icons.info_outline,
          );
          context.read<GroupWalletCubit>().dismissMessage();
        }
      },
      builder: (context, state) {
        if (state is GroupWalletInitial || state is GroupWalletLoading) {
          return const Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(child: CircularProgressIndicator(color: kCyan)),
            ),
          );
        }

        if (state is GroupWalletFailure) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kRose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          final auth = context.read<AuthCubit>().state;
                          if (auth is AuthSuccess) {
                            context.read<GroupWalletCubit>().start(
                              auth.user.uid,
                            );
                          }
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final loaded = state as GroupWalletLoaded;
        final currentUserId = context.read<AuthCubit>().state is AuthSuccess
            ? (context.read<AuthCubit>().state as AuthSuccess).user.uid
            : '';

        // Tích luỹ aggregates
        double totalBalance = 0;
        final uniqueMembers = <String>{};
        final walletNames = <String, String>{};

        for (final w in loaded.wallets) {
          totalBalance += w.balance;
          uniqueMembers.addAll(w.members);
          walletNames[w.id] = w.name;
        }

        // Tạm tính chi/góp từ giao dịch gần đây (hoặc 0 nếu chưa fetch hết)
        // Lưu ý: nếu cần tổng chính xác, phải lưu totalSpent ở model ví
        double totalContributed = 0;
        double totalSpent = 0;
        for (final tx in loaded.allRecentTransactions) {
          if (tx.senderId == currentUserId) {
            if (tx.type == 'expense' || tx.categoryId == 'group_withdraw') {
              totalSpent += tx.amount.abs();
            } else if (tx.categoryId == 'group_contribute') {
              totalContributed += tx.amount.abs();
            }
          }
        }

        return Scaffold(
          backgroundColor: kBgColor,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────
                  GroupWalletHeader(
                    onCreateWallet: () => _openCreatePage(context),
                  ),
                  const SizedBox(height: 24),

                  // ── Invitation banner (if any) ──────────────────────
                  if (loaded.pendingInvitations.isNotEmpty) ...[
                    _InvitationBanner(
                      count: loaded.pendingInvitations.length,
                      onTap: () => _openPendingInvitationsPage(context),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Overview stats ──────────────────────
                  GroupWalletOverviewStats(
                    totalBalance: totalBalance,
                    totalContributed: totalContributed,
                    totalSpent: totalSpent,
                    walletCount: loaded.wallets.length,
                    totalMembers: uniqueMembers.length,
                  ),
                  const SizedBox(height: 26),

                  // ── Wallet cards carousel ──────────────────────
                  GroupWalletCardCarousel(
                    wallets: loaded.wallets,
                    memberNames: loaded.memberNames,
                    memberAvatars: loaded.memberAvatars,
                    onTapWallet: (wallet) => _openWalletDetail(context, wallet),
                  ),
                  const SizedBox(height: 26),

                  // ── Debts ──────────────────────
                  GroupWalletDebtsCard(
                    debts: loaded.myUnsettledDebts,
                    walletNames: walletNames,
                    onSettleDebt: (debt) =>
                        context.read<GroupWalletCubit>().settleDebt(debt.id),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCreatePage(BuildContext context) {
    final groupCubit = context.read<GroupWalletCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: groupCubit,
          child: const CreateGroupWalletPage(),
        ),
      ),
    );
  }

  void _openWalletDetail(BuildContext context, WalletEntity wallet) {
    final groupCubit = context.read<GroupWalletCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => BlocProvider.value(
          value: groupCubit,
          child: GroupWalletDetailPage(walletId: wallet.id),
        ),
      ),
    );
  }

  void _openPendingInvitationsPage(BuildContext context) {
    final groupCubit = context.read<GroupWalletCubit>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => BlocProvider.value(
          value: groupCubit,
          child: const PendingInvitationsPage(),
        ),
      ),
    );
  }
}

/// Invitation banner — inline notification about pending invitations.
class _InvitationBanner extends StatelessWidget {
  const _InvitationBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              kPurple.withValues(alpha: 0.15),
              kCyan.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: kPurple.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPurple.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.mail_rounded, color: kPurple, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lời mời mới',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bạn có $count lời mời tham gia ví nhóm.',
                    style: TextStyle(
                      color: kTextSecondary.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: kPurple.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
