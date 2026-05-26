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
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

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
        if (current is GroupWalletLoaded) {
          return current.message != null && current.message!.isNotEmpty;
        }
        return false;
      },
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
    final nameController = TextEditingController();
    final groupCubit = context.read<GroupWalletCubit>();
    Color selectedAccent = kCyan;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _SheetContainer(
            title: 'Tạo ví nhóm',
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NeoField(
                      controller: nameController,
                      hint: 'Tên ví nhóm (vd: Nhà chung 2026)',
                      prefix: Icon(
                        Icons.group_rounded,
                        color: selectedAccent,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _PaletteRow(
                      selected: selectedAccent,
                      onPick: (color) => setState(() => selectedAccent = color),
                    ),
                    const SizedBox(height: 16),
                    _SheetButton(
                      label: 'Tạo nhóm',
                      color: selectedAccent,
                      onTap: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final success = await groupCubit.createGroupWallet(
                          name,
                          selectedAccent.toARGB32(),
                        );
                        if (success && sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(nameController.dispose);
  }

  void _openWalletDetail(BuildContext context, WalletEntity wallet) {
    final groupCubit = context.read<GroupWalletCubit>();
    groupCubit.selectWallet(wallet.id);
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
