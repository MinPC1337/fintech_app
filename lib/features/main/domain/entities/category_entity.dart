import 'package:equatable/equatable.dart';

enum CategoryType {
  inType,
  outType,
}

class CategoryEntity extends Equatable {
  final String id;
  final String walletId;
  final String name;
  final double budgetLimit;
  final double currentSpent;
  final CategoryType type;

  const CategoryEntity({
    required this.id,
    required this.walletId,
    required this.name,
    required this.budgetLimit,
    required this.currentSpent,
    required this.type,
  });

  @override
  List<Object?> get props => [
        id,
        walletId,
        name,
        budgetLimit,
        currentSpent,
        type,
      ];
}
