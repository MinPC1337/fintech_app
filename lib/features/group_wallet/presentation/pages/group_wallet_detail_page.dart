import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/core/utils/dialog_utils.dart';
import 'group_wallet_transactions_page.dart';
import 'group_wallet_debts_page.dart';
import '../widgets/group_wallet_page/group_wallet_bar_chart.dart';
import '../widgets/group_wallet_detail_page/wallet_card.dart';
import '../widgets/group_wallet_detail_page/quick_action_icon.dart';
import '../widgets/group_wallet_detail_page/member_avatar_tile.dart';
import '../widgets/group_wallet_detail_page/invitation_tile.dart';
import 'group_wallet_members_page.dart';
import 'group_wallet_contribute_page.dart';
import 'group_wallet_withdraw_page.dart';
import 'group_wallet_split_expense_page.dart';

class GroupWalletDetailPage extends StatefulWidget {
  const GroupWalletDetailPage({super.key, required this.walletId});

  final String walletId;

  @override
  State<GroupWalletDetailPage> createState() => _GroupWalletDetailPageState();
}

class _GroupWalletDetailPageState extends State<GroupWalletDetailPage> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      // Chỉ gọi selectWallet nếu state hiện tại chưa có wallet này
      final state = context.read<GroupWalletCubit>().state;
      if (state is! GroupWalletLoaded ||
          state.selectedWallet?.id != widget.walletId) {
        context.read<GroupWalletCubit>().selectWallet(widget.walletId);
      }
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthSuccess) {
          return Scaffold(
            backgroundColor: kBgColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: SafeArea(
              child: Center(
                child: Text(
                  'Cần đăng nhập để xem chi tiết ví nhóm',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return BlocConsumer<GroupWalletCubit, GroupWalletState>(
          listenWhen: (previous, current) {
            if (current is GroupWalletLoaded && current.message != null) {
              if (previous is! GroupWalletLoaded) return true;
              // Chỉ hiện Dialog nếu thông báo mới khác với thông báo cũ
              return current.message != previous.message;
            }
            return false;
          },
          listener: (context, state) {
            if (state is GroupWalletLoaded && state.message != null) {
              // Chỉ hiển thị thông báo nếu người dùng đang thực sự ở trang chi tiết
              if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;

              showNotificationDialog(
                context,
                'Thành công',
                state.message!,
                kEmerald,
                Icons.check_circle_outline,
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
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: kRose,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            final loaded = state as GroupWalletLoaded;

            // Tìm ví trong selectedWallet hoặc trong danh sách ví đã load một cách an toàn
            WalletEntity? wallet = loaded.selectedWallet;

            if (wallet == null || wallet.id != widget.walletId) {
              try {
                wallet = loaded.wallets.firstWhere(
                  (w) => w.id == widget.walletId,
                );
              } catch (_) {
                wallet = null;
              }
            }

            if (wallet == null) {
              return Scaffold(
                backgroundColor: kBgColor,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                body: SafeArea(
                  child: Center(
                    child: Text(
                      'Đang tải chi tiết ví...',
                      style: TextStyle(
                        color: kTextSecondary.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }

            final isOwner = wallet.ownerId == authState.user.uid;
            final members = wallet.members;
            final walletTransactions = loaded.transactions.where((tx) {
              if (tx.type == 'Income') {
                return tx.toWalletId == wallet!.id;
              }
              if (tx.type == 'Expense') {
                return tx.fromWalletId == wallet!.id;
              }
              return false;
            }).toList();

            final walletInvitations = loaded.pendingInvitations
                .where((invite) => invite.walletId == wallet!.id)
                .toList();

            return Scaffold(
              backgroundColor: kBgColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  wallet.name,
                  style: const TextStyle(color: kTextPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              body: SafeArea(
                bottom: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      WalletCard(
                        wallet: wallet,
                        isOwner: isOwner,
                        balance: wallet.balance,
                      ),
                      if (wallet.status == 'closed') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kRose.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: kRose.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: kRose,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  wallet.scheduledDeletionTime != null
                                      ? 'Ví nhóm đã đóng và sẽ bị xóa vĩnh viễn vào ngày ${wallet.scheduledDeletionTime!.day.toString().padLeft(2, '0')}/${wallet.scheduledDeletionTime!.month.toString().padLeft(2, '0')}/${wallet.scheduledDeletionTime!.year}.'
                                      : 'Ví nhóm này đã bị đóng và đang chờ hệ thống xóa.',
                                  style: const TextStyle(
                                    color: kRose,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: wallet.status == 'closed'
                            ? MainAxisAlignment.spaceEvenly
                            : MainAxisAlignment.spaceBetween,
                        children: [
                          if (wallet.status != 'closed') ...[
                            QuickActionIcon(
                              emoji: '📥',
                              label: 'Nạp quỹ',
                              color: kEmerald,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<GroupWalletCubit>(),
                                      child: GroupWalletContributePage(
                                        walletId: wallet!.id,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (isOwner)
                              QuickActionIcon(
                                emoji: '💸',
                                label: 'Chuyển tiền',
                                color: kRose,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context.read<GroupWalletCubit>(),
                                        child: GroupWalletWithdrawPage(
                                          walletId: wallet!.id,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            QuickActionIcon(
                              emoji: '🧮',
                              label: 'Chia tiền',
                              color: kPurple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<GroupWalletCubit>(),
                                      child: GroupWalletSplitExpensePage(
                                        wallet: wallet!,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          QuickActionIcon(
                            emoji: '🕒',
                            label: 'Lịch sử',
                            color: kCyan,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<GroupWalletCubit>(),
                                    child: GroupWalletTransactionsPage(
                                      walletId: wallet!.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          QuickActionIcon(
                            emoji: '🧾',
                            label: 'Nợ',
                            color: const Color(0xFFF59E0B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<GroupWalletCubit>(),
                                    child: GroupWalletDebtsPage(
                                      walletId: wallet!.id,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Thành viên',
                            style: TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupWalletMembersPage(
                                  members: members,
                                  ownerId: wallet!.ownerId,
                                ),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              foregroundColor: kCyan,
                            ),
                            child: const Text('Xem tất cả'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount:
                              members.length +
                              (wallet.status != 'closed'
                                  ? 1
                                  : 0), // +1 for the invite button if not closed
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (wallet!.status != 'closed' && index == 0) {
                              return GestureDetector(
                                onTap: () =>
                                    _showInviteMemberDialog(context, wallet!.id),
                                child: SizedBox(
                                  width: 72,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: kCyan.withValues(alpha: 0.5),
                                            width: 1,
                                          ),
                                          color: kCyan.withValues(alpha: 0.1),
                                        ),
                                        child: const Icon(
                                          Icons.person_add_rounded,
                                          color: kCyan,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Mời',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: kCyan,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            final memberIndex = wallet.status != 'closed'
                                ? index - 1
                                : index;
                            return MemberAvatarTile(
                              memberId: members[memberIndex],
                              isOwner: members[memberIndex] == wallet.ownerId,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GroupWalletMemberDetailPage(
                                    memberId: members[memberIndex],
                                    ownerId: wallet!.ownerId,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (walletTransactions.isNotEmpty) ...[
                        GroupWalletBarChart(transactions: walletTransactions),
                        const SizedBox(height: 20),
                      ],

                      if (walletInvitations.isNotEmpty) ...[
                        const Text(
                          'Lời mời',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...walletInvitations.map(
                          (invite) => InvitationTile(
                            invitation: invite,
                            walletName: wallet!.name,
                            onAccept: () => context
                                .read<GroupWalletCubit>()
                                .acceptInvitation(invite.id),
                            onReject: () => context
                                .read<GroupWalletCubit>()
                                .rejectInvitation(invite.id),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (walletTransactions.isEmpty &&
                          walletInvitations.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Ví nhóm chưa có giao dịch hoặc lời mời nào.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kTextSecondary.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                      if (wallet.status != 'closed') ...[
                        if (wallet.closeApprovals.isNotEmpty) ...[
                          if (isOwner)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: kRose.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: kRose.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              kRose,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Đang chờ xác nhận đóng ví...',
                                      style: TextStyle(
                                        color: kRose,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (!wallet.closeApprovals.contains(
                            authState.user.uid,
                          ))
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kRose.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: kRose.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_rounded,
                                        color: kRose,
                                        size: 24,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Trưởng nhóm yêu cầu đóng ví. Bạn có đồng ý không?',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => context
                                              .read<GroupWalletCubit>()
                                              .rejectCloseGroupWallet(
                                                wallet!.id,
                                              ),
                                          style: TextButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                color: kTextSecondary
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Từ chối',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => context
                                              .read<GroupWalletCubit>()
                                              .approveCloseGroupWallet(
                                                wallet!.id,
                                              ),
                                          style: TextButton.styleFrom(
                                            backgroundColor: kRose,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Đồng ý',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            Center(
                              child: Text(
                                'Bạn đã đồng ý đóng ví. Đang chờ người khác...',
                                style: TextStyle(
                                  color: kRose.withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ] else if (isOwner)
                          Center(
                            child: TextButton.icon(
                              onPressed: () =>
                                  _confirmCloseGroup(context, wallet!.id),
                              icon: const Icon(
                                Icons.lock_outline_rounded,
                                color: kRose,
                                size: 18,
                              ),
                              label: const Text(
                                'Đóng nhóm',
                                style: TextStyle(
                                  color: kRose,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                backgroundColor: kRose.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showInviteMemberDialog(BuildContext context, String walletId) {
    final cubit = context.read<GroupWalletCubit>();
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: AlertDialog(
          backgroundColor: kThemeSurfaceSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: kThemeBorderDefault),
          ),
          title: const Text(
            'Mời thành viên',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                style: const TextStyle(color: kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Email người nhận',
                  hintStyle: const TextStyle(color: kTextSecondary),
                  prefixIcon: const Icon(Icons.email_rounded, color: kCyan),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: kTextSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                final success = await cubit.inviteMember(walletId, email);
                if (success && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Gửi lời mời', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCloseGroup(BuildContext context, String walletId) async {
    final groupCubit = context.read<GroupWalletCubit>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kThemeSurfaceSecondary.withOpacity(0.9),
          title: const Text(
            'Đóng ví nhóm',
            style: TextStyle(color: kTextPrimary),
          ),
          content: const Text(
            'Bạn có chắc muốn đóng ví nhóm này? Sau khi đóng, ví sẽ không còn hoạt động nữa.',
            style: TextStyle(color: kTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy', style: TextStyle(color: kTextSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Đồng ý',
                style: TextStyle(color: kRose, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await groupCubit.closeGroupWallet(walletId);
    }
  }
}
