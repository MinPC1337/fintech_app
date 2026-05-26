import '../../../main/domain/entities/wallet_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchGroupWalletsUseCase {
  final GroupWalletRepository repository;

  WatchGroupWalletsUseCase(this.repository);

  Stream<List<WalletEntity>> call(String userId) {
    return repository.watchGroupWallets(userId);
  }
}
