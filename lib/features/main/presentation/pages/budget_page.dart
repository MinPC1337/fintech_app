import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _currency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final List<_BudgetCategory> _categories = [
    _BudgetCategory(
      name: 'Ăn uống',
      icon: Icons.restaurant_rounded,
      accent: kRose,
      limit: 2500000,
      spent: 1360000,
    ),
    _BudgetCategory(
      name: 'Di chuyển',
      icon: Icons.directions_car_rounded,
      accent: kCyan,
      limit: 1200000,
      spent: 640000,
    ),
    _BudgetCategory(
      name: 'Mua sắm',
      icon: Icons.shopping_bag_rounded,
      accent: kPurple,
      limit: 3000000,
      spent: 2820000,
    ),
    _BudgetCategory(
      name: 'Hóa đơn',
      icon: Icons.receipt_long_rounded,
      accent: kEmerald,
      limit: 1800000,
      spent: 910000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalLimit = _categories.fold<double>(0, (s, c) => s + c.limit);
    final totalSpent = _categories.fold<double>(0, (s, c) => s + c.spent);
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
                subtitle: 'Theo dõi giới hạn chi tiêu theo tháng',
                trailing: _MonthPickerChip(
                  month: _selectedMonth,
                  onPrev: () => _changeMonth(-1),
                  onNext: () => _changeMonth(1),
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
                          value: _formatMoney(totalSpent),
                          color: kRose,
                        ),
                        _Kpi(
                          label: 'CÒN LẠI',
                          value: _formatMoney(remaining),
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
                          'Giới hạn: ${_formatMoney(totalLimit)}',
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
              ..._categories.map((c) => _CategoryCard(
                    category: c,
                    formatMoney: _formatMoney,
                    onEdit: () => _openEditCategorySheet(c),
                  )),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      floatingActionButton: _NeoFab(
        label: 'Thêm danh mục',
        icon: Icons.add_rounded,
        onTap: _openCreateCategorySheet,
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
  }

  String _formatMoney(double value) {
    return _currency.format(value).replaceAll('đ', '').trim();
  }

  void _openCreateCategorySheet() {
    _openCategorySheet(
      initial: _BudgetCategory(
        name: '',
        icon: Icons.category_rounded,
        accent: kCyan,
        limit: 0,
        spent: 0,
      ),
      title: 'Tạo danh mục ngân sách',
      onSave: (cat) {
        setState(() => _categories.add(cat));
      },
    );
  }

  void _openEditCategorySheet(_BudgetCategory existing) {
    _openCategorySheet(
      initial: existing,
      title: 'Chỉnh sửa danh mục',
      onSave: (cat) {
        setState(() {
          final idx = _categories.indexOf(existing);
          if (idx >= 0) _categories[idx] = cat;
        });
      },
      onDelete: () {
        setState(() => _categories.remove(existing));
      },
    );
  }

  void _openCategorySheet({
    required _BudgetCategory initial,
    required String title,
    required ValueChanged<_BudgetCategory> onSave,
    VoidCallback? onDelete,
  }) {
    final nameCtrl = TextEditingController(text: initial.name);
    final limitCtrl = TextEditingController(
      text: initial.limit > 0 ? initial.limit.toStringAsFixed(0) : '',
    );
    final spentCtrl = TextEditingController(
      text: initial.spent > 0 ? initial.spent.toStringAsFixed(0) : '',
    );

    Color selectedAccent = initial.accent;
    IconData selectedIcon = initial.icon;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _SheetContainer(
            title: title,
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _NeoField(
                      controller: nameCtrl,
                      hint: 'Tên danh mục (vd: Ăn uống)',
                      prefix: Icon(selectedIcon, color: selectedAccent, size: 18),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _NeoField(
                            controller: limitCtrl,
                            hint: 'Giới hạn (VND)',
                            keyboardType: TextInputType.number,
                            prefix: const Icon(Icons.shield_rounded, color: kCyan, size: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _NeoField(
                            controller: spentCtrl,
                            hint: 'Đã chi (VND)',
                            keyboardType: TextInputType.number,
                            prefix: const Icon(Icons.payments_rounded, color: kRose, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _PaletteRow(
                      selected: selectedAccent,
                      onPick: (c) => setSheetState(() => selectedAccent = c),
                    ),
                    const SizedBox(height: 10),
                    _IconRow(
                      selected: selectedIcon,
                      onPick: (i) => setSheetState(() => selectedIcon = i),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (onDelete != null)
                          Expanded(
                            child: _SheetButton(
                              label: 'Xóa',
                              color: kRose,
                              onTap: () {
                                Navigator.pop(ctx);
                                onDelete();
                              },
                            ),
                          ),
                        if (onDelete != null) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: _SheetButton(
                            label: 'Lưu',
                            color: kCyan,
                            onTap: () {
                              final name = nameCtrl.text.trim();
                              final limit = double.tryParse(limitCtrl.text.trim()) ?? 0;
                              final spent = double.tryParse(spentCtrl.text.trim()) ?? 0;
                              if (name.isEmpty) return;
                              Navigator.pop(ctx);
                              onSave(
                                _BudgetCategory(
                                  name: name,
                                  icon: selectedIcon,
                                  accent: selectedAccent,
                                  limit: limit,
                                  spent: spent,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      limitCtrl.dispose();
      spentCtrl.dispose();
    });
  }
}

class _BudgetCategory {
  _BudgetCategory({
    required this.name,
    required this.icon,
    required this.accent,
    required this.limit,
    required this.spent,
  });

  final String name;
  final IconData icon;
  final Color accent;
  final double limit;
  final double spent;
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
    required this.category,
    required this.formatMoney,
    required this.onEdit,
  });

  final _BudgetCategory category;
  final String Function(double) formatMoney;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final limit = category.limit;
    final spent = category.spent;
    final remaining = (limit - spent);
    final ratio =
        limit > 0 ? (spent / limit).clamp(0, 1).toDouble() : 0.0;

    final isOver = remaining < 0;
    final accent = isOver ? kRose : category.accent;

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
                    child: Icon(category.icon, color: accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
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
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
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
        keyboardType: keyboardType,
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
