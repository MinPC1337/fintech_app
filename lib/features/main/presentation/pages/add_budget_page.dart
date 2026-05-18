import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/budget_repository.dart';

class AddBudgetPage extends StatefulWidget {
  final String walletId;
  final CategoryEntity? category; // Nếu có là edit

  const AddBudgetPage({super.key, required this.walletId, this.category});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _nameController = TextEditingController();
  final _limitController = TextEditingController();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  Color _selectedColor = kCyan;
  IconData _selectedIcon = Icons.shopping_bag_rounded;

  final List<Color> _palette = [
    kCyan, kPurple, kEmerald, kRose,
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFD946EF), // Fuchsia
    const Color(0xFFF97316), // Orange
    const Color(0xFF06B6D4), // Quantum Cyan
    const Color(0xFF8B5CF6), // Violet
  ];

  final List<IconData> _icons = [
    Icons.shopping_bag_rounded,
    Icons.restaurant_rounded,
    Icons.directions_car_rounded,
    Icons.home_rounded,
    Icons.movie_rounded,
    Icons.fitness_center_rounded,
    Icons.medical_services_rounded,
    Icons.school_rounded,
    Icons.flight_rounded,
    Icons.electrical_services_rounded,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _limitController.text = widget.category!.budgetLimit.toStringAsFixed(0);
      if (widget.category!.accentArgb != null) {
        _selectedColor = Color(widget.category!.accentArgb!);
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final limit = double.tryParse(_limitController.text.trim()) ?? 0;

    if (name.isEmpty || limit <= 0) return;

    final category = CategoryEntity(
      id: widget.category?.id ?? '',
      walletId: widget.walletId,
      name: name,
      budgetLimit: limit,
      currentSpent: widget.category?.currentSpent ?? 0,
      type: CategoryType.outType,
      iconCodePoint: _selectedIcon.codePoint,
      accentArgb: _selectedColor.toARGB32(),
      month: _selectedMonth,
      year: _selectedYear,
    );

    await sl<BudgetRepository>().upsertBudgetCategory(category);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        iconTheme: const IconThemeData(color: kTextPrimary),
        title: Text(
          widget.category == null ? 'Thiết lập Ngân sách' : 'Sửa Ngân sách',
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('THÔNG TIN CƠ BẢN'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _nameController,
              label: 'Tên ngân sách',
              hint: 'Ví dụ: Ăn uống, Di chuyển...',
              icon: Icons.edit_rounded,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _limitController,
              label: 'Hạn mức chi tiêu',
              hint: '0',
              icon: Icons.track_changes_rounded,
              suffix: 'VNĐ',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('THỜI GIAN ÁP DỤNG'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDropdownMonth()),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownYear()),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('PHONG CÁCH'),
            const SizedBox(height: 16),
            _buildColorPicker(),
            const SizedBox(height: 24),
            _buildIconPicker(),

            const SizedBox(height: 48),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: kTextSecondary.withValues(alpha: 0.7),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: kCyan, fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: kTextSecondary.withValues(alpha: 0.4)),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Icon(icon, color: _selectedColor, size: 20),
        suffixText: suffix,
        suffixStyle: const TextStyle(color: kTextSecondary),
        filled: true,
        fillColor: kThemeSurfaceSecondary.withValues(alpha: 0.5),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kThemeBorderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _selectedColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownMonth() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          dropdownColor: kBgColor,
          items: List.generate(12, (i) => i + 1).map((m) {
            return DropdownMenuItem(
              value: m,
              child: Text(
                'Tháng $m',
                style: const TextStyle(color: kTextPrimary),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedMonth = v!),
        ),
      ),
    );
  }

  Widget _buildDropdownYear() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: kThemeSurfaceSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kThemeBorderDefault),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: kBgColor,
          items: [2024, 2025, 2026].map((y) {
            return DropdownMenuItem(
              value: y,
              child: Text(
                'Năm $y',
                style: const TextStyle(color: kTextPrimary),
              ),
            );
          }).toList(),
          onChanged: (v) => setState(() => _selectedYear = v!),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _palette.map((color) {
        final isSelected = _selectedColor == color;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIconPicker() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _icons.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final icon = _icons[index];
          final isSelected = _selectedIcon == icon;
          return GestureDetector(
            onTap: () => setState(() => _selectedIcon = icon),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? _selectedColor : kThemeSurfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.black : kTextSecondary,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _save,
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedColor,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text(
        'LƯU NGÂN SÁCH',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
