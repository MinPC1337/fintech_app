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

  /// Code point Material Icons (lưu Firestore). Null = UI dùng icon mặc định.
  final int? iconCodePoint;

  /// Màu accent ARGB 32-bit (vd `Color(0xFF22D3EE).value`). Null = theme mặc định.
  final int? accentArgb;

  const CategoryEntity({
    required this.id,
    required this.walletId,
    required this.name,
    required this.budgetLimit,
    required this.currentSpent,
    required this.type,
    this.iconCodePoint,
    this.accentArgb,
  });

  @override
  List<Object?> get props => [
        id,
        walletId,
        name,
        budgetLimit,
        currentSpent,
        type,
        iconCodePoint,
        accentArgb,
      ];
}
