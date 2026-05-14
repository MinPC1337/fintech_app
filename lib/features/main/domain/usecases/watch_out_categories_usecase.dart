import '../entities/category_entity.dart';
import '../repositories/budget_repository.dart';
import '../repositories/wallet_repository.dart';

class WatchOutCategoriesUseCase {
  final WalletRepository walletRepository;
  final BudgetRepository budgetRepository;

  WatchOutCategoriesUseCase(this.walletRepository, this.budgetRepository);

  Stream<List<CategoryEntity>> call(
    String userId, {
    int? month,
    int? year,
  }) async* {
    try {
      final wallet = await walletRepository.getPrimaryWallet(userId);
      if (wallet != null) {
        yield* budgetRepository
            .watchBudgetCategories(
              wallet.id,
              month: month ?? DateTime.now().month,
              year: year ?? DateTime.now().year,
            )
            .map(
              (categories) => categories
                  .where((c) => c.type == CategoryType.outType)
                  .toList(),
            );
      } else {
        yield [];
      }
    } catch (e) {
      yield [];
    }
  }
}
