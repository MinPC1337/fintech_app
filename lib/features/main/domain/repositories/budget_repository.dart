import '../entities/category_entity.dart';
import '../entities/transaction_entity.dart';

abstract class BudgetRepository {
  Stream<List<CategoryEntity>> watchBudgetCategories(String walletId);

  Future<void> upsertBudgetCategory(CategoryEntity category);

  Future<void> deleteBudgetCategory(String walletId, String categoryId);

  Stream<List<TransactionEntity>> watchTransactionsForMonth({
    required String userId,
    required int year,
    required int month,
  });
}
