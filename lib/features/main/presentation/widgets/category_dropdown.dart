import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/emoji_mapping.dart';
import '../../domain/entities/category_entity.dart';

class CategoryDropdown extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onChanged;

  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedCategoryId,
      dropdownColor: kSurface,
      style: const TextStyle(color: kTextPrimary, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Chọn danh mục',
        hintStyle: const TextStyle(color: kTextSecondary),
        prefixIcon: const Icon(Icons.category_rounded, color: kElectricBlue),
        filled: true,
        fillColor: kSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: categories.map((cat) {
        return DropdownMenuItem(
          value: cat.id,
          child: Row(
            children: [
              if (cat.emoji != null)
                Text(cat.emoji!, style: const TextStyle(fontSize: 20))
              else
                Text(
                  getEmojiForCategoryName(cat.name),
                  style: const TextStyle(fontSize: 20),
                ),
              const SizedBox(width: 12),
              Text(cat.name),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
