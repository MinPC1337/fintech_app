import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  /// Deposits a specific amount into a wallet and records the transaction atomically.
  Future<void> depositToWallet(String receiverUid, double amount);
  
  /// Gets user's primary wallet
  Future<WalletEntity?> getPrimaryWallet(String userId);

  /// Gets a real-time stream of the user's primary wallet
  Stream<WalletEntity?> getPrimaryWalletStream(String userId);

  /// Transfers a specific amount from the user's wallet out to an external phone/MoMo
  Future<void> transferOut(
    String senderUid,
    double amount,
    String targetPhone,
    String categoryId, {
    String? fromWalletId,
  });

  /// Gets a real-time stream of transactions for a specific user
  Stream<List<dynamic>> getTransactionsStream(String userId);

  /// Chuyển tiền nội bộ từ user này sang user khác trong app
  Future<void> transferToUser(
    String senderUid,
    String receiverUid,
    double amount,
    String categoryId, {
    String? fromWalletId,
  });
}
