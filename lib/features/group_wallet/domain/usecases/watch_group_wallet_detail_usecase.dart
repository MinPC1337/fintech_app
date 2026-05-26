import '../../../main/domain/entities/wallet_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchGroupWalletDetailUseCase {
  final GroupWalletRepository repository;

  WatchGroupWalletDetailUseCase(this.repository);

  Stream<WalletEntity?> call(String walletId) {
    return repository.watchGroupWalletById(walletId);
  }
}
