import '../../../main/domain/entities/debt_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchMyUnsettledDebtsUseCase {
  final GroupWalletRepository repository;

  WatchMyUnsettledDebtsUseCase(this.repository);

  Stream<List<DebtEntity>> call(String userId) {
    return repository.watchMyUnsettledDebts(userId);
  }
}
