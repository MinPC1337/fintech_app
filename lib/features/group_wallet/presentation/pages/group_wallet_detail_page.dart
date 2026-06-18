import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
import '../widgets/group_wallet_detail_page/group_wallet_sheets.dart';
import '../widgets/group_wallet_detail_page/wallet_card.dart';
import '../widgets/group_wallet_detail_page/quick_action_icon.dart';
import '../widgets/group_wallet_detail_page/member_avatar_tile.dart';
import '../widgets/group_wallet_detail_page/invitation_tile.dart';
import 'group_wallet_members_page.dart';

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
                title: const Text(
                  'Chi tiết ví nhóm',
                  style: TextStyle(color: kTextPrimary),
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
                              onTap: () =>
                                  _showContributeSheet(context, wallet!.id),
                            ),
                            if (isOwner)
                              QuickActionIcon(
                                emoji: '💸',
                                label: 'Chuyển tiền',
                                color: kRose,
                                onTap: () =>
                                    _showWithdrawSheet(context, wallet!.id),
                              ),
                            QuickActionIcon(
                              emoji: '🧮',
                              label: 'Chia tiền',
                              color: kPurple,
                              onTap: () =>
                                  _showSplitExpenseSheet(context, wallet!),
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
                                    _showInviteMemberSheet(context, wallet!.id),
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

  Future<void> _showInviteMemberSheet(BuildContext context, String walletId) {
    final cubit = context.read<GroupWalletCubit>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: InviteMemberSheet(walletId: walletId),
      ),
    );
  }

  Future<void> _showContributeSheet(BuildContext context, String walletId) {
    final cubit = context.read<GroupWalletCubit>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ContributeSheet(walletId: walletId),
      ),
    );
  }

  Future<void> _showWithdrawSheet(BuildContext context, String walletId) {
    final cubit = context.read<GroupWalletCubit>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: WithdrawSheet(walletId: walletId),
      ),
    );
  }

  Future<void> _showSplitExpenseSheet(
    BuildContext context,
    WalletEntity wallet,
  ) {
    final cubit = context.read<GroupWalletCubit>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: SplitExpenseSheet(wallet: wallet),
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

class _InviteMemberSheet extends StatefulWidget {
  final String walletId;
  const _InviteMemberSheet({required this.walletId});

  @override
  State<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<_InviteMemberSheet> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SheetContainer(
        title: 'Mời thành viên',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NeoField(
              controller: _emailController,
              hint: 'Email người nhận',
              prefix: const Icon(Icons.email_rounded, color: kCyan, size: 18),
            ),
            const SizedBox(height: 16),
            _SheetButton(
              label: 'Gửi lời mời',
              color: kCyan,
              onTap: () async {
                final email = _emailController.text.trim();
                if (email.isEmpty) return;
                final cubit = context.read<GroupWalletCubit>();
                final success = await cubit.inviteMember(
                  widget.walletId,
                  email,
                );
                if (!mounted) return;
                if (success) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ContributeSheet extends StatefulWidget {
  final String walletId;
  const _ContributeSheet({required this.walletId});

  @override
  State<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<_ContributeSheet> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SheetContainer(
        title: 'Nạp quỹ nhóm',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NeoField(
              controller: _amountController,
              hint: 'Số tiền (VNĐ)',
              prefix: const Icon(
                Icons.monetization_on_rounded,
                color: kEmerald,
                size: 18,
              ),
            ),
            const SizedBox(height: 16),
            _SheetButton(
              label: 'Nạp',
              color: kEmerald,
              onTap: () async {
                final amount =
                    double.tryParse(
                      _amountController.text.replaceAll(',', ''),
                    ) ??
                    0;
                if (amount <= 0) return;
                final cubit = context.read<GroupWalletCubit>();
                final success = await cubit.contributeToGroup(
                  widget.walletId,
                  amount,
                );
                if (!mounted) return;
                if (success) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  final String walletId;
  const _WithdrawSheet({required this.walletId});

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SheetContainer(
        title: 'Rút tiền ví nhóm',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NeoField(
              controller: _amountController,
              hint: 'Số tiền (VNĐ)',
              prefix: const Icon(
                Icons.money_off_rounded,
                color: kRose,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            _NeoField(
              controller: _noteController,
              hint: 'Ghi chú (tùy chọn)',
              prefix: const Icon(
                Icons.note_alt_rounded,
                color: kTextSecondary,
                size: 18,
              ),
            ),
            const SizedBox(height: 16),
            _SheetButton(
              label: 'Rút',
              color: kRose,
              onTap: () async {
                final amount =
                    double.tryParse(
                      _amountController.text.replaceAll(',', ''),
                    ) ??
                    0;
                if (amount <= 0) return;
                final cubit = context.read<GroupWalletCubit>();
                final success = await cubit.withdrawFromGroup(
                  widget.walletId,
                  amount,
                  _noteController.text.trim(),
                );
                if (!mounted) return;
                if (success) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitExpenseSheet extends StatefulWidget {
  final WalletEntity wallet;
  const _SplitExpenseSheet({required this.wallet});

  @override
  State<_SplitExpenseSheet> createState() => _SplitExpenseSheetState();
}

class _SplitExpenseSheetState extends State<_SplitExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late final Set<String> _selectedMembers;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      _currentUserId = authState.user.uid;
      _selectedMembers = {_currentUserId!};
    } else {
      _selectedMembers = {};
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _SheetContainer(
        title: 'Chia tiền nhóm',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NeoField(
              controller: _amountController,
              hint: 'Tổng số tiền (VNĐ)',
              prefix: const Icon(
                Icons.calculate_rounded,
                color: kPurple,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            _NeoField(
              controller: _noteController,
              hint: 'Ghi chú',
              prefix: const Icon(
                Icons.description_rounded,
                color: kTextSecondary,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Thành viên tham gia',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...widget.wallet.members.map((memberId) {
              final isCurrent = memberId == _currentUserId;
              return CheckboxListTile(
                value: _selectedMembers.contains(memberId),
                title: Text(memberId),
                subtitle: isCurrent ? const Text('Bạn') : null,
                activeColor: kPurple,
                onChanged: isCurrent
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            _selectedMembers.add(memberId);
                          } else {
                            _selectedMembers.remove(memberId);
                          }
                        });
                      },
              );
            }),
            const SizedBox(height: 8),
            _SheetButton(
              label: 'Chia',
              color: kPurple,
              onTap: () async {
                final amount =
                    double.tryParse(
                      _amountController.text.replaceAll(',', ''),
                    ) ??
                    0;
                final participantIds = _selectedMembers.toList();
                if (amount <= 0 || participantIds.length < 2) return;
                final cubit = context.read<GroupWalletCubit>();
                final success = await cubit.splitExpense(
                  widget.wallet.id,
                  amount,
                  _noteController.text.trim(),
                  participantIds,
                );
                if (!mounted) return;
                if (success) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatefulWidget {
  final WalletEntity wallet;
  final bool isOwner;
  final double balance;

  const _WalletCard({
    required this.wallet,
    required this.isOwner,
    required this.balance,
  });

  @override
  State<_WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<_WalletCard> {
  bool _isBalanceHidden = false;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  Widget _buildCardChip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE5C07B),
            Color(0xFFF3E5AB),
            Color(0xFFD4AF37),
            Color(0xFFB8860B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 18,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.2),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 14,
            child: Container(
              width: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 14,
            child: Container(
              width: 0.5,
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAccountNumber(String acc) {
    if (acc.length == 10) {
      return '${acc.substring(0, 4)}${acc.substring(4, 7)}${acc.substring(7)}';
    }
    return acc;
  }

  @override
  Widget build(BuildContext context) {
    String rawAcc = widget.wallet.id.hashCode
        .abs()
        .toString()
        .padLeft(10, '0')
        .substring(0, 10);
    String formattedAcc = _formatAccountNumber(rawAcc);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A), // Deep vibrant blue
            Color(0xFF0F172A), // Dark slate
            Color(0xFF020617), // Very dark slate
          ],
          stops: [0.0, 0.6, 1.0],
        ),
        border: Border.all(color: kCyan.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: kCyan.withValues(alpha: 0.05),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Elements (Holographic / Glassmorphism)
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [kCyan.withValues(alpha: 0.15), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kEmerald.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 20,
              child: Icon(
                Icons.language_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Logo + Contactless)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.group_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.wallet.name.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.contactless_rounded,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 24,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Chip
                  _buildCardChip(),

                  const SizedBox(height: 20),

                  // Số tài khoản
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formattedAcc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 22,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: const Offset(0, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      if (widget.wallet.status == 'closed')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kRose.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: kRose.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'ĐÃ ĐÓNG',
                            style: TextStyle(
                              color: kRose,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Footer: Tên + Balance
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SỐ DƯ VÍ NHÓM',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _isBalanceHidden
                                    ? '******'
                                    : currencyFormatter
                                          .format(widget.balance)
                                          .replaceAll('đ', '')
                                          .trim(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'đ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Nút ẩn hiện + Logo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isBalanceHidden = !_isBalanceHidden;
                              });
                            },
                            child: Icon(
                              _isBalanceHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withValues(alpha: 0.5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Premium Logo
                          Text(
                            widget.isOwner ? 'CHỦ NHÓM' : 'THÀNH VIÊN',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: kThemeBorderDefault),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _NeoField extends StatelessWidget {
  const _NeoField({required this.controller, required this.hint, this.prefix});

  final TextEditingController controller;
  final String hint;
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: kTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.7)),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          prefixIcon: prefix,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
