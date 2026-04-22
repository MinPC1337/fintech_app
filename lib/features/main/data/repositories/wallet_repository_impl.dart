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

  @override
  Future<void> transferOut(String senderUid, double amount, String targetPhone) async {
    await remoteDataSource.transferOut(senderUid, amount, targetPhone);
  }

  @override
  Stream<List<dynamic>> getTransactionsStream(String userId) {
    return remoteDataSource.getTransactionsStream(userId);
  }
}
