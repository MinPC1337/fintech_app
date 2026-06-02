import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/auth/data/models/user_model.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';
import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/core/utils/dialog_utils.dart';

class GroupWalletDetailPage extends StatefulWidget {
  const GroupWalletDetailPage({super.key, required this.walletId});

  final String walletId;

  @override
  State<GroupWalletDetailPage> createState() => _GroupWalletDetailPageState();
}

class _GroupWalletDetailPageState extends State<GroupWalletDetailPage> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _hasInitialized = false;

  String _formatMoney(double value) {
    return _currency.format(value).replaceAll('đ', '').trim();
  }

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
            final walletDebts = loaded.debts
                .where((debt) => debt.walletId == wallet!.id)
                .toList();
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
                      _GlassHero(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wallet.status == 'active'
                                            ? 'Đang hoạt động'
                                            : 'Đã đóng',
                                        style: TextStyle(
                                          color: kTextSecondary.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatMoney(wallet.balance),
                                        style: const TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Số dư ví nhóm',
                                        style: TextStyle(
                                          color: kTextSecondary.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  wallet.status == 'active'
                                      ? Icons.group_rounded
                                      : Icons.lock_rounded,
                                  color: wallet.status == 'active'
                                      ? kCyan
                                      : kTextSecondary,
                                  size: 34,
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                _Pill(
                                  icon: Icons.person_outline,
                                  text: '${members.length} thành viên',
                                  color: kCyan,
                                ),
                                const SizedBox(width: 10),
                                _Pill(
                                  icon: Icons.account_balance_wallet_outlined,
                                  text: isOwner
                                      ? 'Bạn là chủ nhóm'
                                      : 'Thành viên',
                                  color: kPurple,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _ActionChip(
                            label: 'Mời thành viên',
                            icon: Icons.person_add_rounded,
                            color: kCyan,
                            onTap: () =>
                                _showInviteMemberSheet(context, wallet!.id),
                          ),
                          _ActionChip(
                            label: 'Nạp quỹ',
                            icon: Icons.arrow_downward_rounded,
                            color: kEmerald,
                            onTap: () =>
                                _showContributeSheet(context, wallet!.id),
                          ),
                          _ActionChip(
                            label: 'Chia tiền',
                            icon: Icons.account_balance_outlined,
                            color: kPurple,
                            onTap: () =>
                                _showSplitExpenseSheet(context, wallet!),
                          ),
                          if (isOwner)
                            _ActionChip(
                              label: 'Rút tiền',
                              icon: Icons.arrow_upward_rounded,
                              color: kRose,
                              onTap: () =>
                                  _showWithdrawSheet(context, wallet!.id),
                            ),
                          if (isOwner && wallet.status != 'closed')
                            _ActionChip(
                              label: 'Đóng nhóm',
                              icon: Icons.lock_open_rounded,
                              color: kTextSecondary,
                              onTap: () =>
                                  _confirmCloseGroup(context, wallet!.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Thành viên',
                            style: TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _GroupWalletMembersPage(
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
                          itemCount: members.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return _MemberAvatarTile(
                              memberId: members[index],
                              isOwner: members[index] == wallet!.ownerId,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _GroupWalletMemberDetailPage(
                                    memberId: members[index],
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
                        const Text(
                          'Giao dịch gần đây',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...walletTransactions
                            .take(4)
                            .map(
                              (tx) => _TransactionTile(
                                transaction: tx,
                                walletId: wallet!.id,
                                formatMoney: _formatMoney,
                              ),
                            ),
                        const SizedBox(height: 20),
                      ],
                      if (walletDebts.isNotEmpty) ...[
                        const Text(
                          'Công nợ',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...walletDebts.map(
                          (debt) => _DebtTile(
                            debt: debt,
                            currentUserId: authState.user.uid,
                            formatMoney: _formatMoney,
                            onSettle:
                                debt.borrowerId == authState.user.uid &&
                                    !debt.isSettled
                                ? () => context
                                      .read<GroupWalletCubit>()
                                      .settleDebt(debt.id)
                                : null,
                            onRemind:
                                debt.lenderId == authState.user.uid &&
                                    !debt.isSettled
                                ? () => context
                                      .read<GroupWalletCubit>()
                                      .remindDebt(debt.id)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (walletInvitations.isNotEmpty) ...[
                        const Text(
                          'Lời mời',
                          style: TextStyle(
                            color: kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...walletInvitations.map(
                          (invite) => _InvitationTile(
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
                          walletDebts.isEmpty &&
                          walletInvitations.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'Ví nhóm chưa có giao dịch, công nợ hoặc lời mời nào.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: kTextSecondary.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
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
        child: _InviteMemberSheet(walletId: walletId),
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
        child: _ContributeSheet(walletId: walletId),
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
        child: _WithdrawSheet(walletId: walletId),
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
        child: _SplitExpenseSheet(wallet: wallet),
      ),
    );
  }

  Future<void> _confirmCloseGroup(BuildContext context, String walletId) async {
    final groupCubit = context.read<GroupWalletCubit>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: kThemeSurfaceSecondary,
          title: const Text('Đóng ví nhóm'),
          content: const Text(
            'Bạn có chắc muốn đóng ví nhóm này? Sau khi đóng, ví sẽ không còn hoạt động nữa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Đồng ý'),
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

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.walletId,
    required this.formatMoney,
  });

  final TransactionEntity transaction;
  final String walletId;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final isIncrease = transaction.toWalletId == walletId;
    final icon = isIncrease
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final accent = isIncrease ? kEmerald : kRose;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.note.isNotEmpty
                      ? transaction.note
                      : (isIncrease
                            ? 'Giao dịch tăng ví nhóm'
                            : 'Giao dịch giảm ví nhóm'),
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(transaction.timestamp),
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${formatMoney(transaction.amount)} đ',
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({
    required this.debt,
    required this.currentUserId,
    required this.formatMoney,
    this.onSettle,
    this.onRemind,
  });

  final DebtEntity debt;
  final String currentUserId;
  final String Function(double) formatMoney;
  final VoidCallback? onSettle;
  final VoidCallback? onRemind;

  Future<String> _fetchDisplayName(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists || doc.data() == null) return uid;
      final data = doc.data()!;
      final name = (data['fullName'] ?? data['displayName'] ?? data['name']);
      if (name is String && name.isNotEmpty) return name;
    } catch (_) {}
    return uid;
  }

  @override
  Widget build(BuildContext context) {
    final isBorrower = debt.borrowerId == currentUserId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kRose.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.currency_exchange_rounded,
              color: kRose,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _fetchDisplayName(
                    isBorrower ? debt.lenderId : debt.borrowerId,
                  ),
                  builder: (context, snapshot) {
                    final other =
                        snapshot.data ??
                        (isBorrower ? debt.lenderId : debt.borrowerId);
                    return Text(
                      isBorrower ? 'Bạn nợ $other' : 'Được $other nợ',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  'Số tiền: ${formatMoney(debt.amount)} đ',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  debt.isSettled ? 'Đã thanh toán' : 'Chưa thanh toán',
                  style: TextStyle(
                    color: debt.isSettled ? kEmerald : kRose,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (onRemind != null) ...[
            GestureDetector(
              onTap: onRemind,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kCyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Nhắc nợ',
                  style: TextStyle(
                    color: kCyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (onSettle != null)
            GestureDetector(
              onTap: onSettle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: kEmerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Thanh toán',
                  style: TextStyle(
                    color: kEmerald,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({
    required this.invitation,
    required this.walletName,
    required this.onAccept,
    required this.onReject,
  });

  final InvitationEntity invitation;
  final String walletName;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lời mời tham gia nhóm "$walletName"',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Từ: ${invitation.senderEmail}',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Email nhận: ${invitation.receiverEmail}',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SheetButton(
                  label: 'Chấp nhận',
                  color: kEmerald,
                  onTap: onAccept,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SheetButton(
                  label: 'Từ chối',
                  color: kRose,
                  onTap: onReject,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassHero extends StatelessWidget {
  const _GlassHero({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: kCyan.withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: -12,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: kThemeSurfacePrimary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kCyan.withValues(alpha: 0.10),
                  kPurple.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: kTextPrimary.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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

class _GroupWalletMembersPage extends StatelessWidget {
  const _GroupWalletMembersPage({required this.members, required this.ownerId});

  final List<String> members;
  final String ownerId;

  Future<List<UserModel>> _loadMemberUsers() async {
    final firestore = FirebaseFirestore.instance;
    final users = await Future.wait(
      members.map((memberId) async {
        try {
          final doc = await firestore.collection('users').doc(memberId).get();
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromJson(doc.data()!);
        } catch (_) {
          return null;
        }
      }),
    );
    return users.whereType<UserModel>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tất cả thành viên',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _loadMemberUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Không có thông tin thành viên nào.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              return _MemberListTile(
                user: user,
                isOwner: user.uid == ownerId,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _GroupWalletMemberDetailPage(
                      memberId: user.uid,
                      ownerId: ownerId,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _GroupWalletMemberDetailPage extends StatelessWidget {
  const _GroupWalletMemberDetailPage({
    required this.memberId,
    required this.ownerId,
  });

  final String memberId;
  final String ownerId;

  Future<UserModel?> _fetchMember() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Thông tin thành viên',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: _fetchMember(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: kCyan));
          }
          final member = snapshot.data;
          if (member == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Không thể tải thông tin thành viên.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: _MemberAvatarCircle(
                    avatarUrl: member.avatarUrl,
                    initials: _memberInitials(member.fullName, member.uid),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    member.fullName.isNotEmpty ? member.fullName : 'Thành viên',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    member.uid == ownerId ? 'Chủ nhóm' : 'Thành viên',
                    style: TextStyle(
                      color: kTextSecondary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailRow(
                  label: 'Email',
                  value: member.email.isNotEmpty ? member.email : 'Chưa có',
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Tên hiển thị',
                  value: member.fullName.isNotEmpty
                      ? member.fullName
                      : 'Chưa có',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _memberInitials(String fullName, String uid) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return uid.substring(0, uid.length.clamp(1, 2)).toUpperCase();
  }
}

class _MemberListTile extends StatelessWidget {
  const _MemberListTile({
    required this.user,
    required this.isOwner,
    required this.onTap,
  });

  final UserModel user;
  final bool isOwner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kThemeSurfaceSecondary,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _MemberAvatarCircle(
                avatarUrl: user.avatarUrl,
                initials: _memberInitials(user.fullName, user.uid),
                borderColor: isOwner ? kPurple : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isNotEmpty ? user.fullName : 'Thành viên',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isNotEmpty ? user.email : user.uid,
                      style: TextStyle(
                        color: kTextSecondary.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: kPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Chủ',
                    style: TextStyle(
                      color: kPurple,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _memberInitials(String fullName, String uid) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return uid.substring(0, uid.length.clamp(1, 2)).toUpperCase();
  }
}

class _MemberAvatarTile extends StatelessWidget {
  const _MemberAvatarTile({
    required this.memberId,
    required this.onTap,
    this.isOwner = false,
  });

  final String memberId;
  final VoidCallback onTap;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .snapshots(),
      builder: (context, snapshot) {
        final user =
            snapshot.hasData &&
                snapshot.data!.exists &&
                snapshot.data!.data() != null
            ? UserModel.fromJson(snapshot.data!.data()!)
            : null;
        final initials = _memberInitials(user?.fullName ?? '', memberId);
        final displayName = user?.fullName.isNotEmpty == true
            ? user!.fullName
            : memberId;
        return GestureDetector(
          onTap: onTap,
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
                      color: isOwner ? kPurple : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: user != null && user.avatarUrl.isNotEmpty
                        ? Image.network(
                            user.avatarUrl,
                            width: 58,
                            height: 58,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _fallbackAvatar(initials),
                          )
                        : _fallbackAvatar(initials),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fallbackAvatar(String initials) {
    return Container(
      color: kCyan.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: kCyan, fontWeight: FontWeight.w900),
      ),
    );
  }

  String _memberInitials(String fullName, String uid) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return uid.substring(0, uid.length.clamp(1, 2)).toUpperCase();
  }
}

class _MemberAvatarCircle extends StatelessWidget {
  const _MemberAvatarCircle({
    required this.avatarUrl,
    required this.initials,
    this.borderColor,
  });

  final String avatarUrl;
  final String initials;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderColor != null ? 2 : 0,
        ),
      ),
      child: ClipOval(
        child: avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _fallbackCircle(initials),
              )
            : _fallbackCircle(initials),
      ),
    );
  }

  Widget _fallbackCircle(String initials) {
    return Container(
      color: kCyan.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: kCyan,
          fontSize: 30,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.85),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: kTextPrimary.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
