import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  /// Deposits a specific amount into a wallet and records the transaction atomically.
  Future<void> depositToWallet(String receiverUid, double amount);
  
  /// Gets user's primary wallet
  Future<WalletEntity?> getPrimaryWallet(String userId);

  /// Gets a real-time stream of the user's primary wallet
  Stream<WalletEntity?> getPrimaryWalletStream(String userId);
}
