import 'package:equatable/equatable.dart';

enum CategoryType { inType, outType }

class CategoryEntity extends Equatable {
  final String id;
  final String walletId;
  final String name;
  final double budgetLimit;
  final double currentSpent;
  final CategoryType type;
  final int? month;
  final int? year;

  /// Emoji for displaying the category. Null = UI uses default emoji based on category name.
  final String? emoji;

  const CategoryEntity({
    required this.id,
    required this.walletId,
    required this.name,
    required this.budgetLimit,
    required this.currentSpent,
    required this.type,
    this.emoji,
    this.month,
    this.year,
  });

  @override
  List<Object?> get props => [
    id,
    walletId,
    name,
    budgetLimit,
    currentSpent,
    type,
    emoji,
    month,
    year,
  ];
}
