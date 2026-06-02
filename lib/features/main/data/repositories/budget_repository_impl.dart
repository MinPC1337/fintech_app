import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_data_source.dart';
import '../models/category_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl({required this.remoteDataSource});

  final BudgetRemoteDataSource remoteDataSource;

  @override
  Stream<List<CategoryEntity>> watchBudgetCategories(
    String walletId, {
    int? month,
    int? year,
  }) {
    return remoteDataSource.watchBudgetCategories(
      walletId,
      month: month,
      year: year,
    );
  }

  @override
  Future<void> upsertBudgetCategory(CategoryEntity category) async {
    await remoteDataSource.upsertBudgetCategory(
      CategoryModel(
        id: category.id,
        walletId: category.walletId,
        name: category.name,
        budgetLimit: category.budgetLimit,
        currentSpent: category.currentSpent,
        type: category.type,
        emoji: category.emoji,
        month: category.month,
        year: category.year,
      ),
    );
  }

  @override
  Future<void> deleteBudgetCategory(String walletId, String categoryId) async {
    await remoteDataSource.deleteBudgetCategory(walletId, categoryId);
  }

  @override
  Stream<List<TransactionEntity>> watchTransactionsForMonth({
    required String userId,
    required int year,
    required int month,
  }) {
    return remoteDataSource.watchTransactionsForMonth(
      userId: userId,
      year: year,
      month: month,
    );
  }
}
