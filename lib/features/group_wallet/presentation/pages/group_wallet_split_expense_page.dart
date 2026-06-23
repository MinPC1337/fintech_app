import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/features/auth/data/models/user_model.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

class GroupWalletSplitExpensePage extends StatefulWidget {
  final WalletEntity wallet;

  const GroupWalletSplitExpensePage({super.key, required this.wallet});

  @override
  State<GroupWalletSplitExpensePage> createState() =>
      _GroupWalletSplitExpensePageState();
}

class _GroupWalletSplitExpensePageState
    extends State<GroupWalletSplitExpensePage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedMembers = {};
  String? _currentUserId;
  bool _isSubmitting = false;

  late Future<List<UserModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      _currentUserId = authState.user.uid;
      _selectedMembers.add(_currentUserId!);
    }
    _membersFuture = _loadMemberUsers();
  }

  Future<List<UserModel>> _loadMemberUsers() async {
    final firestore = FirebaseFirestore.instance;
    final users = await Future.wait(
      widget.wallet.members.map((memberId) async {
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
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleSplit() async {
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final participantIds = _selectedMembers.toList();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ')),
      );
      return;
    }

    if (participantIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần ít nhất 2 thành viên để chia tiền')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final cubit = context.read<GroupWalletCubit>();
    final success = await cubit.splitExpense(
      widget.wallet.id,
      amount,
      _noteController.text.trim(),
      participantIds,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
    }
  }

  String _getInitials(String fullName, String uid) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return uid.substring(0, uid.length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        title: const Text(
          'Chia tiền nhóm',
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
                            color: kPurple.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [AppGlows.purple],
                          ),
                          child: const Text(
                            '🧮',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chia tiền',
                                style: TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Chia đều hóa đơn cho các thành viên',
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

              _buildLabel('Tổng số tiền'),
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
                  icon: Icons.calculate_rounded,
                  iconColor: kPurple,
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
                  hint: 'Ví dụ: Ăn trưa tại nhà hàng',
                  icon: Icons.description_rounded,
                  iconColor: kTextSecondary,
                ),
              ),

              const SizedBox(height: 24),

              _buildLabel('Thành viên tham gia'),
              const SizedBox(height: 12),

              FutureBuilder<List<UserModel>>(
                future: _membersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: kPurple),
                    );
                  }
                  final users = snapshot.data ?? [];
                  if (users.isEmpty) {
                    return const Text(
                      'Không thể tải danh sách thành viên.',
                      style: TextStyle(color: kRose),
                    );
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: kThemeSurfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kThemeBorderDefault),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: kThemeBorderDefault),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isCurrent = user.uid == _currentUserId;
                        final isSelected = _selectedMembers.contains(user.uid);

                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          activeColor: kPurple,
                          checkColor: Colors.white,
                          checkboxShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          value: isSelected,
                          onChanged: isCurrent
                              ? null
                              : (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedMembers.add(user.uid);
                                    } else {
                                      _selectedMembers.remove(user.uid);
                                    }
                                  });
                                },
                          title: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: kPurple.withValues(alpha: 0.2),
                                backgroundImage: user.avatarUrl.isNotEmpty
                                    ? NetworkImage(user.avatarUrl)
                                    : null,
                                child: user.avatarUrl.isEmpty
                                    ? Text(
                                        _getInitials(user.fullName, user.uid),
                                        style: const TextStyle(
                                          color: kPurple,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          user.fullName.isNotEmpty
                                              ? user.fullName
                                              : 'Thành viên',
                                          style: const TextStyle(
                                            color: kTextPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: kPurple.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Bạn',
                                              style: TextStyle(
                                                color: kPurple,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.email.isNotEmpty
                                          ? user.email
                                          : user.uid,
                                      style: TextStyle(
                                        color: kTextSecondary.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Nút Chia tiền
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSplit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  disabledBackgroundColor: kPurple.withValues(alpha: 0.4),
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
                            Icons.call_split_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Xác nhận chia tiền',
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
