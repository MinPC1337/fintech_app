import 'package:equatable/equatable.dart';

import '../../domain/entities/category_entity.dart';

class BudgetLineItem extends Equatable {
  const BudgetLineItem({
    required this.category,
    required this.spentThisMonth,
  });

  final CategoryEntity category;
  final double spentThisMonth;

  double get budgetLimit => category.budgetLimit;

  @override
  List<Object?> get props => [category, spentThisMonth];
}

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

class BudgetInitial extends BudgetState {}

class BudgetLoading extends BudgetState {}

class BudgetNoAuth extends BudgetState {}

class BudgetNoWallet extends BudgetState {}

class BudgetFailure extends BudgetState {
  const BudgetFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class BudgetLoaded extends BudgetState {
  const BudgetLoaded({
    required this.month,
    required this.items,
    required this.walletId,
    this.errorMessage,
  });

  final DateTime month;
  final List<BudgetLineItem> items;
  final String walletId;

  /// Lỗi từ thao tác CRUD (không chặn toàn trang).
  final String? errorMessage;

  double get totalLimit =>
      items.fold<double>(0, (s, i) => s + i.budgetLimit);

  double get totalSpent =>
      items.fold<double>(0, (s, i) => s + i.spentThisMonth);

  @override
  List<Object?> get props => [month, items, walletId, errorMessage];
}
