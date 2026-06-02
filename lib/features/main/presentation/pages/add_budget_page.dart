import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/emoji_mapping.dart';
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
  String _selectedEmoji = predefinedEmojis[0];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _limitController.text = widget.category!.budgetLimit.toStringAsFixed(0);
      if (widget.category!.emoji != null) {
        _selectedEmoji = widget.category!.emoji!;
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
      emoji: _selectedEmoji,
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

            _buildSectionTitle('BIỂU TƯỢNG'),
            const SizedBox(height: 16),
            _buildEmojiPicker(),

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
        prefixIcon: Icon(icon, color: kCyan, size: 20),
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
          borderSide: const BorderSide(color: kCyan, width: 1.5),
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

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: predefinedEmojis.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final emoji = predefinedEmojis[index];
          final isSelected = _selectedEmoji == emoji;
          return GestureDetector(
            onTap: () => setState(() => _selectedEmoji = emoji),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? kCyan.withValues(alpha: 0.2)
                    : kThemeSurfaceSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? kCyan : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
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
        backgroundColor: kCyan,
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
