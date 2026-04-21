import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wallet_entity.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<void> depositToWallet(String receiverUid, double amount);
  Future<WalletModel?> getPrimaryWallet(String userId);
  Stream<WalletModel?> getPrimaryWalletStream(String userId);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore firestore;

  WalletRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> depositToWallet(String receiverUid, double amount) async {
    // 1. Tìm ví chính của user
    final walletsQuery = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: receiverUid)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (walletsQuery.docs.isEmpty) {
      throw Exception('Không tìm thấy ví cá nhân của người dùng này');
    }

    final walletDoc = walletsQuery.docs.first;

    // 2. Chạy Transaction đảm bảo tính nguyên tử
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletDoc.reference);

      if (!snapshot.exists) {
        throw Exception('Ví không tồn tại');
      }

      // Đọc số dư hiện tại
      final currentBalance = (snapshot.data()?['balance'] ?? 0).toDouble();
      final newBalance = currentBalance + amount;

      // Cập nhật số dư
      transaction.update(walletDoc.reference, {'balance': newBalance});

      // Tạo bản ghi giao dịch (Income)
      final txRef = firestore.collection('transactions').doc();
      final txData = {
        'id': txRef.id,
        'toWalletId': walletDoc.id,
        'receiverId': receiverUid,
        'amount': amount,
        'categoryId': 'deposit', // Category mặc định cho nạp tiền
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Income', // Metadata thêm để filter
        'note': 'Nạp tiền vào ví',
      };
      transaction.set(txRef, txData);
    });
  }

  @override
  Future<WalletModel?> getPrimaryWallet(String userId) async {
    final doc = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      return WalletModel.fromJson({...doc.docs.first.data(), 'id': doc.docs.first.id});
    }
    return null;
  }

  @override
  Stream<WalletModel?> getPrimaryWalletStream(String userId) {
    return firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return WalletModel.fromJson(
            {...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
      }
      return null;
    });
  }
}
