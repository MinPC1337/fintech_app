import '../../../main/domain/entities/debt_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchDebtsUseCase {
  final GroupWalletRepository repository;

  WatchDebtsUseCase(this.repository);

  Stream<List<DebtEntity>> call(String walletId) {
    return repository.watchDebts(walletId);
  }
}
