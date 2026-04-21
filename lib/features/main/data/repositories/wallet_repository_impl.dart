import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> depositToWallet(String receiverUid, double amount) async {
    await remoteDataSource.depositToWallet(receiverUid, amount);
  }

  @override
  Future<WalletEntity?> getPrimaryWallet(String userId) async {
    return await remoteDataSource.getPrimaryWallet(userId);
  }

  @override
  Stream<WalletEntity?> getPrimaryWalletStream(String userId) {
    return remoteDataSource.getPrimaryWalletStream(userId);
  }
}
