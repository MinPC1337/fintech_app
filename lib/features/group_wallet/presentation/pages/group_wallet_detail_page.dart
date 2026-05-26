import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';
import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

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
      context.read<GroupWalletCubit>().selectWallet(widget.walletId);
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
          listener: (context, state) {
            if (state is GroupWalletLoaded && state.message != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message!)));
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
            final wallet = loaded.selectedWallet;
            if (wallet == null || wallet.id != widget.walletId) {
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
            final walletTransactions = loaded.transactions;
            final walletDebts = loaded.debts
                .where((debt) => debt.walletId == wallet.id)
                .toList();
            final walletInvitations = loaded.pendingInvitations
                .where((invite) => invite.walletId == wallet.id)
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
                                _showInviteMemberSheet(context, wallet.id),
                          ),
                          _ActionChip(
                            label: 'Nạp quỹ',
                            icon: Icons.arrow_downward_rounded,
                            color: kEmerald,
                            onTap: () =>
                                _showContributeSheet(context, wallet.id),
                          ),
                          _ActionChip(
                            label: 'Chia tiền',
                            icon: Icons.account_balance_outlined,
                            color: kPurple,
                            onTap: () =>
                                _showSplitExpenseSheet(context, wallet),
                          ),
                          if (isOwner)
                            _ActionChip(
                              label: 'Rút tiền',
                              icon: Icons.arrow_upward_rounded,
                              color: kRose,
                              onTap: () =>
                                  _showWithdrawSheet(context, wallet.id),
                            ),
                          if (isOwner && wallet.status != 'closed')
                            _ActionChip(
                              label: 'Đóng nhóm',
                              icon: Icons.lock_open_rounded,
                              color: kTextSecondary,
                              onTap: () =>
                                  _confirmCloseGroup(context, wallet.id),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Thành viên',
                        style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: members.map((memberId) {
                          final display = memberId.length > 4
                              ? memberId.substring(0, 4).toUpperCase()
                              : memberId;
                          return _MemberChip(text: display, accent: kCyan);
                        }).toList(),
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

  Future<void> _showInviteMemberSheet(
    BuildContext context,
    String walletId,
  ) async {
    final emailController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _SheetContainer(
            title: 'Mời thành viên',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NeoField(
                  controller: emailController,
                  hint: 'Email người nhận',
                  prefix: const Icon(
                    Icons.email_rounded,
                    color: kCyan,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 16),
                _SheetButton(
                  label: 'Gửi lời mời',
                  color: kCyan,
                  onTap: () async {
                    final email = emailController.text.trim();
                    if (email.isEmpty) return;
                    final success = await context
                        .read<GroupWalletCubit>()
                        .inviteMember(walletId, email);
                    if (success && sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future.microtask(() => emailController.dispose());
    });
  }

  Future<void> _showContributeSheet(
    BuildContext context,
    String walletId,
  ) async {
    final amountController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _SheetContainer(
            title: 'Nạp quỹ nhóm',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NeoField(
                  controller: amountController,
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
                          amountController.text.replaceAll(',', ''),
                        ) ??
                        0;
                    if (amount <= 0) return;
                    final success = await context
                        .read<GroupWalletCubit>()
                        .contributeToGroup(walletId, amount);
                    if (success && sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future.microtask(() => amountController.dispose());
    });
  }

  Future<void> _showWithdrawSheet(BuildContext context, String walletId) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _SheetContainer(
            title: 'Rút tiền ví nhóm',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _NeoField(
                  controller: amountController,
                  hint: 'Số tiền (VNĐ)',
                  prefix: const Icon(
                    Icons.money_off_rounded,
                    color: kRose,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 12),
                _NeoField(
                  controller: noteController,
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
                          amountController.text.replaceAll(',', ''),
                        ) ??
                        0;
                    if (amount <= 0) return;
                    final success = await context
                        .read<GroupWalletCubit>()
                        .withdrawFromGroup(
                          walletId,
                          amount,
                          noteController.text.trim(),
                        );
                    if (success && sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      Future.microtask(() {
        amountController.dispose();
        noteController.dispose();
      });
    });
  }

  Future<void> _showSplitExpenseSheet(
    BuildContext context,
    WalletEntity wallet,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) return;

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final userId = authState.user.uid;
    final selected = <String>{userId};

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: _SheetContainer(
                title: 'Chia tiền nhóm',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NeoField(
                      controller: amountController,
                      hint: 'Tổng số tiền (VNĐ)',
                      prefix: const Icon(
                        Icons.calculate_rounded,
                        color: kPurple,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _NeoField(
                      controller: noteController,
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
                    ...wallet.members.map((memberId) {
                      final isCurrent = memberId == userId;
                      return CheckboxListTile(
                        value: selected.contains(memberId),
                        title: Text(memberId),
                        subtitle: isCurrent ? const Text('Bạn') : null,
                        activeColor: kPurple,
                        onChanged: isCurrent
                            ? null
                            : (value) {
                                setState(() {
                                  if (value == true) {
                                    selected.add(memberId);
                                  } else {
                                    selected.remove(memberId);
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
                        final groupCubit = context.read<GroupWalletCubit>();
                        final amount =
                            double.tryParse(
                              amountController.text.replaceAll(',', ''),
                            ) ??
                            0;
                        final participantIds = selected.toList();
                        if (amount <= 0 || participantIds.length < 2) return;
                        final success = await groupCubit.splitExpense(
                          wallet.id,
                          amount,
                          noteController.text.trim(),
                          participantIds,
                        );
                        if (success && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      Future.microtask(() {
        amountController.dispose();
        noteController.dispose();
      });
    });
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

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.formatMoney,
  });

  final TransactionEntity transaction;
  final String Function(double) formatMoney;

  @override
  Widget build(BuildContext context) {
    final icon = transaction.type == 'Income'
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final accent = transaction.type == 'Income' ? kEmerald : kRose;
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
                      : 'Giao dịch nhóm',
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
  });

  final DebtEntity debt;
  final String currentUserId;
  final String Function(double) formatMoney;
  final VoidCallback? onSettle;

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
                Text(
                  isBorrower
                      ? 'Bạn nợ ${debt.lenderId}'
                      : 'Được ${debt.borrowerId} nợ',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
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
    required this.onAccept,
    required this.onReject,
  });

  final InvitationEntity invitation;
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
            'Lời mời tham gia ví nhóm',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Từ: ${invitation.senderId}',
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
          prefixIcon: prefix == null ? null : Center(child: prefix),
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
