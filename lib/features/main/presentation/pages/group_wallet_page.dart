import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class GroupWalletPage extends StatefulWidget {
  const GroupWalletPage({super.key});

  @override
  State<GroupWalletPage> createState() => _GroupWalletPageState();
}

class _GroupWalletPageState extends State<GroupWalletPage> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final List<_GroupWallet> _wallets = [
    _GroupWallet(
      name: 'Chuyến đi Đà Lạt',
      accent: kPurple,
      balance: 3250000,
      members: const ['HA', 'TN', 'QP', 'LM'],
      yourShare: 820000,
      status: _GroupStatus.active,
    ),
    _GroupWallet(
      name: 'Nhà chung 2026',
      accent: kCyan,
      balance: 7420000,
      members: const ['NA', 'VT', 'LH'],
      yourShare: 2100000,
      status: _GroupStatus.active,
    ),
    _GroupWallet(
      name: 'Quỹ sinh nhật',
      accent: kEmerald,
      balance: 0,
      members: const ['HN', 'KP', 'DT', 'MH', 'TA'],
      yourShare: 0,
      status: _GroupStatus.closed,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _wallets.fold<double>(0, (s, w) => s + w.balance);
    final activeCount = _wallets.where((w) => w.status == _GroupStatus.active).length;

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
                    onTap: _openCreateGroupSheet,
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
                          _formatMoney(total),
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
                          text: '${_wallets.length - activeCount} nhóm đã đóng',
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
              ..._wallets.map(
                (w) => _GroupCard(
                  wallet: w,
                  formatMoney: _formatMoney,
                  onOpen: () => _openGroupDetail(w),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(double value) {
    return _currency.format(value).replaceAll('đ', '').trim();
  }

  void _openGroupDetail(_GroupWallet w) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _SheetContainer(
          title: w.name,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MiniStatRow(
                leftLabel: 'Số dư ví nhóm',
                leftValue: '${_formatMoney(w.balance)} VND',
                rightLabel: 'Phần của bạn',
                rightValue: '${_formatMoney(w.yourShare)} VND',
                accent: w.accent,
              ),
              const SizedBox(height: 14),
              Text(
                'Thành viên',
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: w.members
                    .map(
                      (m) => _MemberChip(
                        text: m,
                        accent: w.accent,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'Nạp vào quỹ',
                      color: kCyan,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetButton(
                      label: 'Chia tiền',
                      color: kPurple,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateGroupSheet() {
    final nameCtrl = TextEditingController();
    Color selectedAccent = kCyan;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _SheetContainer(
            title: 'Tạo ví nhóm',
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NeoField(
                      controller: nameCtrl,
                      hint: 'Tên ví nhóm (vd: Nhà chung 2026)',
                      prefix: Icon(Icons.group_rounded, color: selectedAccent, size: 18),
                    ),
                    const SizedBox(height: 14),
                    _PaletteRow(
                      selected: selectedAccent,
                      onPick: (c) => setSheetState(() => selectedAccent = c),
                    ),
                    const SizedBox(height: 16),
                    _SheetButton(
                      label: 'Tạo nhóm',
                      color: selectedAccent,
                      onTap: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() {
                          _wallets.insert(
                            0,
                            _GroupWallet(
                              name: name,
                              accent: selectedAccent,
                              balance: 0,
                              members: const ['Bạn'],
                              yourShare: 0,
                              status: _GroupStatus.active,
                            ),
                          );
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(nameCtrl.dispose);
  }
}

enum _GroupStatus { active, closed }

class _GroupWallet {
  _GroupWallet({
    required this.name,
    required this.accent,
    required this.balance,
    required this.members,
    required this.yourShare,
    required this.status,
  });

  final String name;
  final Color accent;
  final double balance;
  final List<String> members;
  final double yourShare;
  final _GroupStatus status;
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

  final _GroupWallet wallet;
  final String Function(double) formatMoney;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final accent = wallet.status == _GroupStatus.active ? wallet.accent : kTextSecondary;
    final statusText = wallet.status == _GroupStatus.active ? 'Đang hoạt động' : 'Đã đóng';
    final statusIcon =
        wallet.status == _GroupStatus.active ? Icons.bolt_rounded : Icons.lock_rounded;

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: kThemeGlassBase,
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
                        'Bạn: ${formatMoney(wallet.yourShare)}',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _AvatarRow(
                      members: wallet.members,
                      accent: accent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
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

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({required this.members, required this.accent});

  final List<String> members;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(4).toList();
    final extra = members.length - shown.length;

    return Row(
      children: [
        ...shown.asMap().entries.map(
          (e) {
            final idx = e.key;
            final text = e.value;
            return Transform.translate(
              offset: Offset(-8.0 * idx, 0),
              child: _Avatar(text: text, accent: accent),
            );
          },
        ),
        if (extra > 0)
          Transform.translate(
            offset: Offset(-8.0 * shown.length, 0),
            child: _Avatar(text: '+$extra', accent: kTextSecondary),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: kBgColor,
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: kTextPrimary.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w900,
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
          color: kThemeGlassBase,
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
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.accent,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget stat(String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: kTextSecondary.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        stat(leftLabel, leftValue),
        const SizedBox(width: 12),
        stat(rightLabel, rightValue),
      ],
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

class _NeoField extends StatelessWidget {
  const _NeoField({
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
        style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700),
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
  const _SheetButton({required this.label, required this.color, required this.onTap});

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
                      BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 14),
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
