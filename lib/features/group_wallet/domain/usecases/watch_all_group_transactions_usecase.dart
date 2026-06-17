import '../../../main/domain/entities/transaction_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchAllGroupTransactionsUseCase {
  final GroupWalletRepository repository;

  WatchAllGroupTransactionsUseCase(this.repository);

  Stream<List<TransactionEntity>> call(List<String> walletIds) {
    return repository.watchAllGroupTransactions(walletIds);
  }
}
