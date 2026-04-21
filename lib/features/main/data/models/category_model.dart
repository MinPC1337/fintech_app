import 'package:fintech_app/features/main/domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.walletId,
    required super.name,
    required super.budgetLimit,
    required super.currentSpent,
    required super.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      name: json['name'] ?? '',
      budgetLimit: (json['budgetLimit'] ?? 0).toDouble(),
      currentSpent: (json['currentSpent'] ?? 0).toDouble(),
      type: json['type'] == 'outType' ? CategoryType.outType : CategoryType.inType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'name': name,
      'budgetLimit': budgetLimit,
      'currentSpent': currentSpent,
      'type': type == CategoryType.outType ? 'outType' : 'inType',
    };
  }
}
