import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart' as di;
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/entities/category_entity.dart';
import '../cubit/budget_cubit.dart';
import '../cubit/budget_state.dart';

String _formatBudgetMoney(double value) {
  final currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  return currency.format(value).replaceAll('đ', '').trim();
}

IconData _budgetCategoryIcon(CategoryEntity c) {
  final p = c.iconCodePoint;
  if (p != null) {
    return IconData(p, fontFamily: 'MaterialIcons');
  }
  return Icons.category_rounded;
}

Color _budgetCategoryAccent(CategoryEntity c) {
  final a = c.accentArgb;
  if (a != null) {
    return Color(a);
  }
  return kCyan;
}

int _colorToArgb(Color color) {
  final a = (color.a * 255.0).round() & 0xff;
  final r = (color.r * 255.0).round() & 0xff;
  final g = (color.g * 255.0).round() & 0xff;
  final b = (color.b * 255.0).round() & 0xff;
  return (a << 24) | (r << 16) | (g << 8) | b;
}

/// Chuỗi nhập kiểu `2500000`, `2.500.000`, `2,500,000` → số VND.
double? _parseMoneyVndInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
  if (digitsOnly.isEmpty) return null;
  return double.tryParse(digitsOnly);
}

void _showBudgetCategorySheet(
  BuildContext context, {
  required String walletId,
  required String title,
  CategoryEntity? existing,
}) {
  final cubit = context.read<BudgetCubit>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => BlocProvider<BudgetCubit>.value(
      value: cubit,
      child: _BudgetCategoryFormSheet(
        walletId: walletId,
        title: title,
        existing: existing,
      ),
    ),
  );
}

class _BudgetCategoryFormSheet extends StatefulWidget {
  const _BudgetCategoryFormSheet({
    required this.walletId,
    required this.title,
    this.existing,
  });

  final String walletId;
  final String title;
  final CategoryEntity? existing;

  @override
  State<_BudgetCategoryFormSheet> createState() => _BudgetCategoryFormSheetState();
}

class _BudgetCategoryFormSheetState extends State<_BudgetCategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _limitCtrl;
  late Color _accent;
  late IconData _icon;
  bool _saving = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _limitCtrl = TextEditingController(
      text: e != null && e.budgetLimit > 0 ? e.budgetLimit.toStringAsFixed(0) : '',
    );
    _accent = e != null && e.accentArgb != null ? Color(e.accentArgb!) : kCyan;
    _icon = e?.iconCodePoint != null
        ? IconData(e!.iconCodePoint!, fontFamily: 'MaterialIcons')
        : Icons.category_rounded;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _localError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final limit = _parseMoneyVndInput(_limitCtrl.text);
    if (limit == null || limit <= 0) {
      setState(() => _localError = 'Nhập giới hạn là số dương (vd: 2500000 hoặc 2.500.000)');
      return;
    }

    setState(() => _saving = true);
    FocusScope.of(context).unfocus();

    final cubit = context.read<BudgetCubit>();
    final ok = await cubit.upsertCategory(
      walletId: widget.walletId,
      id: widget.existing?.id ?? '',
      name: name,
      budgetLimit: limit,
      type: CategoryType.outType,
      iconCodePoint: _icon.codePoint,
      accentArgb: _colorToArgb(_accent),
    );

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final e = widget.existing;
    if (e == null) return;
    setState(() {
      _saving = true;
      _localError = null;
    });
    FocusScope.of(context).unfocus();
    final ok = await context.read<BudgetCubit>().deleteCategory(widget.walletId, e.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxH = MediaQuery.of(context).size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Material(
            color: Colors.transparent,
            child: _SheetContainer(
              title: widget.title,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_localError != null) ...[
                        Text(
                          _localError!,
                          style: const TextStyle(
                            color: kRose,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _NeoField(
                        controller: _nameCtrl,
                        hint: 'Tên danh mục (vd: Ăn uống)',
                        prefix: Icon(_icon, color: _accent, size: 18),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vui lòng nhập tên danh mục';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _NeoField(
                        controller: _limitCtrl,
                        hint: 'Giới hạn VND (vd: 2500000 hoặc 2.500.000)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        prefix: const Icon(Icons.shield_rounded, color: kCyan, size: 18),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d\s.,]')),
                        ],
                        validator: (v) {
                          final parsed = _parseMoneyVndInput(v ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Nhập số tiền dương';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _PaletteRow(
                        selected: _accent,
                        onPick: (c) => setState(() => _accent = c),
                      ),
                      const SizedBox(height: 10),
                      _IconRow(
                        selected: _icon,
                        onPick: (i) => setState(() => _icon = i),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (widget.existing != null)
                            Expanded(
                              child: _SheetButton(
                                label: 'Xóa',
                                color: kRose,
                                enabled: !_saving,
                                onTap: _delete,
                              ),
                            ),
                          if (widget.existing != null) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _SheetButton(
                              label: _saving ? 'Đang lưu…' : 'Lưu',
                              color: kCyan,
                              enabled: !_saving,
                              onTap: _submit,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

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
                  'Cần đăng nhập để xem ngân sách',
                  style: TextStyle(
                    color: kTextSecondary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }
        return BlocProvider(
          key: ValueKey(authState.user.uid),
          create: (_) => di.sl<BudgetCubit>()..start(authState.user.uid),
          child: const _BudgetScaffold(),
        );
      },
    );
  }
}

class _BudgetScaffold extends StatelessWidget {
  const _BudgetScaffold();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BudgetCubit, BudgetState>(
      listenWhen: (prev, curr) {
        if (curr is! BudgetLoaded) return false;
        final msg = curr.errorMessage;
        if (msg == null || msg.isEmpty) return false;
        if (prev is BudgetLoaded && prev.errorMessage == msg) return false;
        return true;
      },
      listener: (context, state) {
        final s = state as BudgetLoaded;
        final msg = s.errorMessage;
        if (msg != null && msg.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
          context.read<BudgetCubit>().dismissError();
        }
      },
      builder: (context, state) {
        if (state is BudgetInitial || state is BudgetLoading) {
          return const Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(child: CircularProgressIndicator(color: kCyan)),
            ),
          );
        }
        if (state is BudgetNoWallet) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Chưa có ví cá nhân. Tạo ví để dùng ngân sách.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kTextSecondary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        if (state is BudgetFailure) {
          return Scaffold(
            backgroundColor: kBgColor,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kRose, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          final auth = context.read<AuthCubit>().state;
                          if (auth is AuthSuccess) {
                            context.read<BudgetCubit>().start(auth.user.uid);
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
        if (state is! BudgetLoaded) {
          return const Scaffold(backgroundColor: kBgColor, body: SizedBox.shrink());
        }

        final loaded = state;
        final totalLimit = loaded.totalLimit;
        final totalSpent = loaded.totalSpent;
        final remaining =
            (totalLimit - totalSpent).clamp(0, double.infinity).toDouble();
        final ratio = totalLimit > 0
            ? (totalSpent / totalLimit).clamp(0, 1).toDouble()
            : 0.0;

        return Scaffold(
          backgroundColor: kBgColor,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    title: 'NGÂN SÁCH',
                    subtitle: 'Theo dõi giới hạn và chi tiêu thực tế theo tháng',
                    trailing: _MonthPickerChip(
                      month: loaded.month,
                      onPrev: () => context.read<BudgetCubit>().changeMonth(-1),
                      onNext: () => context.read<BudgetCubit>().changeMonth(1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _Kpi(
                              label: 'ĐÃ CHI',
                              value: _formatBudgetMoney(totalSpent),
                              color: kRose,
                            ),
                            _Kpi(
                              label: 'CÒN LẠI',
                              value: _formatBudgetMoney(remaining),
                              color: kEmerald,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 10,
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: Colors.white.withValues(alpha: 0.06),
                              valueColor: const AlwaysStoppedAnimation<Color>(kCyan),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Giới hạn: ${_formatBudgetMoney(totalLimit)}',
                              style: TextStyle(
                                color: kTextSecondary.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(ratio * 100).round()}%',
                              style: const TextStyle(
                                color: kCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'DANH MỤC',
                    style: TextStyle(
                      color: kTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (loaded.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Chưa có danh mục chi. Nhấn "Thêm danh mục" để bắt đầu.',
                        style: TextStyle(
                          color: kTextSecondary.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ...loaded.items.map(
                    (item) => _CategoryCard(
                      item: item,
                      formatMoney: _formatBudgetMoney,
                      onEdit: () => _showBudgetCategorySheet(
                        context,
                        walletId: loaded.walletId,
                        title: 'Chỉnh sửa danh mục',
                        existing: item.category,
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
          floatingActionButton: _NeoFab(
            label: 'Thêm danh mục',
            icon: Icons.add_rounded,
            onTap: () => _showBudgetCategorySheet(
              context,
              walletId: loaded.walletId,
              title: 'Tạo danh mục ngân sách',
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        trailing,
      ],
    );
  }
}

class _MonthPickerChip extends StatelessWidget {
  const _MonthPickerChip({
    required this.month,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: kCyan.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kCyan.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPrev,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, color: kCyan, size: 18),
          ),
          const SizedBox(width: 6),
          Text(
            DateFormat('MM/yyyy').format(month),
            style: const TextStyle(
              color: kCyan,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onNext,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_right, color: kCyan, size: 18),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                  kPurple.withValues(alpha: 0.06),
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

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$value VND',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.item,
    required this.formatMoney,
    required this.onEdit,
  });

  final BudgetLineItem item;
  final String Function(double) formatMoney;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cat = item.category;
    final limit = item.budgetLimit;
    final spent = item.spentThisMonth;
    final remaining = (limit - spent);
    final ratio =
        limit > 0 ? (spent / limit).clamp(0, 1).toDouble() : 0.0;

    final isOver = remaining < 0;
    final baseAccent = _budgetCategoryAccent(cat);
    final accent = isOver ? kRose : baseAccent;
    final icon = _budgetCategoryIcon(cat);

    return GestureDetector(
      onTap: onEdit,
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
                    child: Icon(icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(
                            color: kTextPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giới hạn ${formatMoney(limit)} • Đã chi ${formatMoney(spent)}',
                          style: TextStyle(
                            color: kTextSecondary.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOver
                        ? 'Vượt ${formatMoney(-remaining)}'
                        : 'Còn ${formatMoney(remaining)}',
                    style: TextStyle(
                      color: isOver ? kRose : kTextSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${(ratio * 100).round()}%',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
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

class _NeoFab extends StatelessWidget {
  const _NeoFab({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 92),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kCyan.withValues(alpha: 0.22)),
                  boxShadow: [
                    BoxShadow(
                      color: kCyan.withValues(alpha: 0.22),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: kCyan),
                    const SizedBox(width: 10),
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
            ),
          ),
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

class _NeoField extends StatelessWidget {
  const _NeoField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefix,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Widget? prefix;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.7)),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          prefixIcon: prefix == null ? null : Center(child: prefix),
          errorStyle: const TextStyle(
            color: kRose,
            fontSize: 11,
            fontWeight: FontWeight.w600,
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
    this.enabled = true,
  });

  final String label;
  final Color color;
  final Future<void> Function()? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.35);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled
            ? () async {
                await onTap?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: effectiveColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: effectiveColor.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
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
            'Màu chủ đạo',
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

class _IconRow extends StatelessWidget {
  const _IconRow({required this.selected, required this.onPick});

  final IconData selected;
  final ValueChanged<IconData> onPick;

  @override
  Widget build(BuildContext context) {
    final icons = <IconData>[
      Icons.restaurant_rounded,
      Icons.local_grocery_store_rounded,
      Icons.receipt_long_rounded,
      Icons.directions_car_rounded,
      Icons.movie_rounded,
      Icons.health_and_safety_rounded,
      Icons.school_rounded,
      Icons.category_rounded,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: icons
          .map(
            (i) => GestureDetector(
              onTap: () => onPick(i),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: selected == i ? 0.06 : 0.03),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == i
                        ? kCyan.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  i,
                  color: selected == i ? kCyan : Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
