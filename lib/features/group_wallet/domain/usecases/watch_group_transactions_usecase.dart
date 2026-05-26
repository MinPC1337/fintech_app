import '../../../main/domain/entities/transaction_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchGroupTransactionsUseCase {
  final GroupWalletRepository repository;

  WatchGroupTransactionsUseCase(this.repository);

  Stream<List<TransactionEntity>> call(String walletId) {
    return repository.watchGroupTransactions(walletId);
  }
}
