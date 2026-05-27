import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fintech_app/core/theme/app_colors.dart';
import 'package:fintech_app/injection_container.dart' as di;
import 'package:fintech_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fintech_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_cubit.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';
import 'package:fintech_app/features/group_wallet/presentation/pages/group_wallet_detail_page.dart';
import 'package:fintech_app/features/group_wallet/presentation/pages/pending_invitations_page.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/core/utils/dialog_utils.dart';

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
    final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    String formatMoney(double value) {
      return currency.format(value).replaceAll('đ', '').trim();
    }

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
        final totalBalance = loaded.wallets.fold<double>(
          0,
          (sum, wallet) => sum + wallet.balance,
        );
        final activeCount = loaded.wallets
            .where((wallet) => wallet.status == 'active')
            .length;
        final closedCount = loaded.wallets.length - activeCount;

        return Scaffold(
          backgroundColor: kBgColor,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: _TitleBlock(
                          title: 'VÍ NHÓM',
                          subtitle: 'Quản lý quỹ chung, minh bạch đóng góp',
                        ),
                      ),
                      _ActionIcon(
                        icon: Icons.add_rounded,
                        label: 'Tạo',
                        onTap: () => _openCreateGroupSheet(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _GlassHero(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG QUỸ ĐANG QUẢN LÝ',
                          style: TextStyle(
                            color: kTextSecondary.withValues(alpha: 0.75),
                            letterSpacing: 1.6,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatMoney(totalBalance),
                              style: const TextStyle(
                                color: kTextPrimary,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6),
                              child: Text(
                                'VND',
                                style: TextStyle(
                                  color: kCyan,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _Pill(
                              icon: Icons.group_outlined,
                              text: '$activeCount nhóm hoạt động',
                              color: kCyan,
                            ),
                            const SizedBox(width: 10),
                            _Pill(
                              icon: Icons.lock_outline_rounded,
                              text: '$closedCount nhóm đã đóng',
                              color: kTextSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  if (loaded.pendingInvitations.isNotEmpty) ...[
                    _InvitationSummaryCard(
                      pendingCount: loaded.pendingInvitations.length,
                      onTap: () => _openPendingInvitationsPage(context),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'DANH SÁCH VÍ',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (loaded.wallets.isEmpty)
                    _EmptyStateCard(
                      onTapCreate: () => _openCreateGroupSheet(context),
                    )
                  else
                    ...loaded.wallets.map(
                      (wallet) => _GroupCard(
                        wallet: wallet,
                        formatMoney: formatMoney,
                        onOpen: () => _openWalletDetail(context, wallet),
                      ),
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

  void _openCreateGroupSheet(BuildContext context) {
    final groupCubit = context.read<GroupWalletCubit>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _CreateGroupSheetContent(
            groupCubit: groupCubit,
            sheetContext: sheetContext,
          ),
        );
      },
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

class _CreateGroupSheetContent extends StatefulWidget {
  const _CreateGroupSheetContent({
    required this.groupCubit,
    required this.sheetContext,
  });

  final GroupWalletCubit groupCubit;
  final BuildContext sheetContext;

  @override
  State<_CreateGroupSheetContent> createState() =>
      _CreateGroupSheetContentState();
}

class _CreateGroupSheetContentState extends State<_CreateGroupSheetContent> {
  late TextEditingController nameController;
  Color selectedAccent = kCyan;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetContainer(
      title: 'Tạo ví nhóm mới',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mô tả
          Text(
            'Đặt tên ví nhóm để bắt đầu quản lý quỹ chung.',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),

          _NeoField(
            label: 'Tên ví nhóm',
            controller: nameController,
            hint: 'Ví dụ: Nhà chung 2026, Du lịch...',
            prefix: Icon(Icons.group_rounded, color: selectedAccent, size: 18),
          ),
          const SizedBox(height: 28),

          // Chọn màu
          Text(
            'Chọn màu sắc',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedAccent.withValues(alpha: 0.2),
                    border: Border.all(color: selectedAccent, width: 2),
                  ),
                  child: Icon(
                    Icons.palette_rounded,
                    color: selectedAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PaletteRow(
                    selected: selectedAccent,
                    onPick: (color) => setState(() => selectedAccent = color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Nút tạo
          _SheetButton(
            label: 'Tạo ví nhóm',
            color: selectedAccent,
            onTap: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                showNotificationDialog(
                  widget.sheetContext,
                  'Lỗi',
                  'Vui lòng nhập tên ví nhóm để bắt đầu.',
                  kRose,
                  Icons.warning_amber_rounded,
                );
                return;
              }
              final success = await widget.groupCubit.createGroupWallet(
                name,
                selectedAccent.toARGB32(),
              );
              if (success && widget.sheetContext.mounted) {
                Navigator.pop(widget.sheetContext);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _InvitationSummaryCard extends StatelessWidget {
  const _InvitationSummaryCard({
    required this.pendingCount,
    required this.onTap,
  });

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lời mời mới',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bạn có $pendingCount lời mời tham gia ví nhóm.',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _SheetButton(label: 'Xem lời mời', color: kCyan, onTap: onTap),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({required this.onTapCreate});

  final VoidCallback onTapCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bạn chưa có ví nhóm nào.',
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tạo ví nhóm để theo dõi đóng góp, chia sẻ chi phí và quản lý giao dịch chung.',
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          _SheetButton(label: 'Tạo ví nhóm', color: kCyan, onTap: onTapCreate),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: kTextSecondary.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.wallet,
    required this.formatMoney,
    required this.onOpen,
  });

  final WalletEntity wallet;
  final String Function(double) formatMoney;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = wallet.status == 'active'
        ? Color(wallet.accentArgb ?? kCyan.toARGB32())
        : kTextSecondary;
    final statusText = wallet.status == 'active' ? 'Đang hoạt động' : 'Đã đóng';
    final statusIcon = wallet.status == 'active'
        ? Icons.bolt_rounded
        : Icons.lock_rounded;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kThemeSurfaceSecondary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(-4, 0),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.group_rounded, color: accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wallet.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, color: accent, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: kTextSecondary.withValues(alpha: 0.85),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${formatMoney(wallet.balance)} đ',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${wallet.members.length} thành viên',
                        style: TextStyle(
                          color: kTextSecondary.withValues(alpha: 0.75),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kThemeSurfaceSecondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kThemeBorderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: kCyan, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.bold,
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
  const _NeoField({
    required this.controller,
    required this.hint,
    this.prefix,
    this.label,
  });

  final TextEditingController controller;
  final String hint;
  final Widget? prefix;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      cursorColor: Colors.white,
      cursorWidth: 2.5,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kCyan, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontWeight: FontWeight.w400,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: prefix,
        prefixIconConstraints: const BoxConstraints(minWidth: 40),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        isDense: true,
        filled: true,
        fillColor: kThemeSurfaceSecondary.withValues(alpha: 0.6),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: kCyan.withValues(alpha: 0.8),
            width: 1.5,
          ),
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

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.selected, required this.onPick});

  final Color selected;
  final ValueChanged<Color> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[kCyan, kPurple, kRose, kEmerald, kElectricBlue];
    return Row(
      children: [
        ...colors.map(
          (c) => Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onPick(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.withValues(alpha: 0.25),
                  border: Border.all(
                    color: c,
                    width: selected == c ? 2.5 : 1.2,
                  ),
                  boxShadow: [
                    if (selected == c)
                      BoxShadow(
                        color: c.withValues(alpha: 0.35),
                        blurRadius: 14,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Màu nhóm',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: kTextSecondary.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
