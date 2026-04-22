import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/wallet_entity.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<void> depositToWallet(String receiverUid, double amount);
  Future<WalletModel?> getPrimaryWallet(String userId);
  Stream<WalletModel?> getPrimaryWalletStream(String userId);
  Future<void> transferOut(String senderUid, double amount, String targetPhone);
  Stream<List<TransactionModel>> getTransactionsStream(String userId);
  /// Chuyển tiền nội bộ từ user này sang user khác trong app
  Future<void> transferToUser(String senderUid, String receiverUid, double amount);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore firestore;

  WalletRemoteDataSourceImpl({required this.firestore});

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getPrimaryWalletDoc(
    String userId,
  ) async {
    final walletsQuery = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (walletsQuery.docs.isEmpty) return null;
    return walletsQuery.docs.first;
  }

  @override
  Future<void> depositToWallet(String receiverUid, double amount) async {
    // 1. Tìm ví chính của user
    final walletDoc = await _getPrimaryWalletDoc(receiverUid);
    if (walletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của người dùng này');
    }

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
        'userId': receiverUid, // Bản ghi này thuộc về receiver
        'amount': amount,
        'categoryId': 'deposit',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Income',
        'note': 'Nạp tiền vào ví',
      };
      transaction.set(txRef, txData);
    });
  }

  @override
  Future<WalletModel?> getPrimaryWallet(String userId) async {
    final walletDoc = await _getPrimaryWalletDoc(userId);

    if (walletDoc != null) {
      return WalletModel.fromJson({...walletDoc.data(), 'id': walletDoc.id});
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
            return WalletModel.fromJson({
              ...snapshot.docs.first.data(),
              'id': snapshot.docs.first.id,
            });
          }
          return null;
        });
  }

  @override
  Future<void> transferOut(
    String senderUid,
    double amount,
    String targetPhone,
  ) async {
    // 1. Tìm ví chính của user
    final walletDoc = await _getPrimaryWalletDoc(senderUid);
    if (walletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của người dùng này');
    }

    // 2. Chạy Transaction đảm bảo tính nguyên tử
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(walletDoc.reference);

      if (!snapshot.exists) {
        throw Exception('Ví không tồn tại');
      }

      // Đọc số dư hiện tại
      final currentBalance = (snapshot.data()?['balance'] ?? 0).toDouble();

      if (currentBalance < amount) {
        throw Exception('Số dư không đủ để chuyển khoản');
      }

      final newBalance = currentBalance - amount;

      // Cập nhật số dư
      transaction.update(walletDoc.reference, {'balance': newBalance});

      // Tạo bản ghi giao dịch (Expense/Transfer)
      final txRef = firestore.collection('transactions').doc();
      final txData = {
        'id': txRef.id,
        'fromWalletId': walletDoc.id,
        'senderId': senderUid,
        'receiverId': targetPhone,
        'userId': senderUid, // Bản ghi này thuộc về sender
        'amount': amount,
        'categoryId': 'transfer',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': 'Chuyển khoản đến MoMo $targetPhone',
      };
      transaction.set(txRef, txData);
    });
  }

  @override
  Stream<List<TransactionModel>> getTransactionsStream(String userId) {
    // Query đơn giản theo 'userId' — mỗi bản ghi chỉ thuộc về 1 user duy nhất
    return firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp).toDate().toIso8601String();
            } else if (data['timestamp'] == null) {
              data['timestamp'] = DateTime.now().toIso8601String();
            }
            return TransactionModel.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  @override
  Future<void> transferToUser(
    String senderUid,
    String receiverUid,
    double amount,
  ) async {
    // 1. Tìm ví chính của sender và receiver
    final senderWalletDoc = await _getPrimaryWalletDoc(senderUid);
    if (senderWalletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của bạn');
    }

    final receiverWalletDoc = await _getPrimaryWalletDoc(receiverUid);
    if (receiverWalletDoc == null) {
      throw Exception('Không tìm thấy ví của người nhận. Kiểm tra lại UID.');
    }

    // 2. Chạy Firestore Transaction nguyên tử
    await firestore.runTransaction((transaction) async {
      final senderSnap = await transaction.get(senderWalletDoc.reference);
      final receiverSnap = await transaction.get(receiverWalletDoc.reference);

      if (!senderSnap.exists || !receiverSnap.exists) {
        throw Exception('Ví không tồn tại');
      }

      final senderBalance = (senderSnap.data()?['balance'] ?? 0).toDouble();
      if (senderBalance < amount) {
        throw Exception('Số dư không đủ để thực hiện giao dịch');
      }

      final receiverBalance = (receiverSnap.data()?['balance'] ?? 0).toDouble();

      // Cập nhật số dư cả hai ví
      transaction.update(senderWalletDoc.reference, {'balance': senderBalance - amount});
      transaction.update(receiverWalletDoc.reference, {'balance': receiverBalance + amount});

      final now = DateTime.now().toIso8601String();

      // Ghi giao dịch Expense cho sender (userId = senderUid)
      final senderTxRef = firestore.collection('transactions').doc();
      transaction.set(senderTxRef, {
        'id': senderTxRef.id,
        'fromWalletId': senderWalletDoc.id,
        'toWalletId': receiverWalletDoc.id,
        'senderId': senderUid,
        'receiverId': receiverUid,
        'userId': senderUid, // Bản ghi này thuộc về sender
        'amount': amount,
        'categoryId': 'internal_transfer',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': 'Chuyển tiền đến ví $receiverUid',
      });

      // Ghi giao dịch Income cho receiver (userId = receiverUid)
      final receiverTxRef = firestore.collection('transactions').doc();
      transaction.set(receiverTxRef, {
        'id': receiverTxRef.id,
        'fromWalletId': senderWalletDoc.id,
        'toWalletId': receiverWalletDoc.id,
        'senderId': senderUid,
        'receiverId': receiverUid,
        'userId': receiverUid, // Bản ghi này thuộc về receiver
        'amount': amount,
        'categoryId': 'internal_transfer',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Income',
        'note': 'Nhận tiền từ ví $senderUid',
      });
    });
  }
}
