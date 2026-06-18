import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';

class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.title, required this.child});

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

class NeoField extends StatelessWidget {
  const NeoField({
    super.key,
    required this.controller,
    required this.hint,
    this.prefix,
  });

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

class SheetButton extends StatelessWidget {
  const SheetButton({
    super.key,
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

class InviteMemberSheet extends StatefulWidget {
  final String walletId;
  const InviteMemberSheet({super.key, required this.walletId});

  @override
  State<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends State<InviteMemberSheet> {
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
      child: SheetContainer(
        title: 'Mời thành viên',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoField(
              controller: _emailController,
              hint: 'Email người nhận',
              prefix: const Icon(Icons.email_rounded, color: kCyan, size: 18),
            ),
            const SizedBox(height: 16),
            SheetButton(
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

class ContributeSheet extends StatefulWidget {
  final String walletId;
  const ContributeSheet({super.key, required this.walletId});

  @override
  State<ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends State<ContributeSheet> {
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
      child: SheetContainer(
        title: 'Nạp quỹ nhóm',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoField(
              controller: _amountController,
              hint: 'Số tiền (VNĐ)',
              prefix: const Icon(
                Icons.monetization_on_rounded,
                color: kEmerald,
                size: 18,
              ),
            ),
            const SizedBox(height: 16),
            SheetButton(
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

class WithdrawSheet extends StatefulWidget {
  final String walletId;
  const WithdrawSheet({super.key, required this.walletId});

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
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
      child: SheetContainer(
        title: 'Rút tiền ví nhóm',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoField(
              controller: _amountController,
              hint: 'Số tiền (VNĐ)',
              prefix: const Icon(
                Icons.money_off_rounded,
                color: kRose,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            NeoField(
              controller: _noteController,
              hint: 'Ghi chú (tùy chọn)',
              prefix: const Icon(
                Icons.note_alt_rounded,
                color: kTextSecondary,
                size: 18,
              ),
            ),
            const SizedBox(height: 16),
            SheetButton(
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

class SplitExpenseSheet extends StatefulWidget {
  final WalletEntity wallet;
  const SplitExpenseSheet({super.key, required this.wallet});

  @override
  State<SplitExpenseSheet> createState() => _SplitExpenseSheetState();
}

class _SplitExpenseSheetState extends State<SplitExpenseSheet> {
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
      child: SheetContainer(
        title: 'Chia tiền nhóm',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NeoField(
              controller: _amountController,
              hint: 'Tổng số tiền (VNĐ)',
              prefix: const Icon(
                Icons.calculate_rounded,
                color: kPurple,
                size: 18,
              ),
            ),
            const SizedBox(height: 12),
            NeoField(
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
            SheetButton(
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
