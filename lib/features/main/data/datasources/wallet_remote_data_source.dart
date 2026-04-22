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
        'receiverId': targetPhone, // Cho app demo, lưu sdt vào receiverId
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
    // Lấy các giao dịch liên quan đến user (là sender hoặc receiver)
    // Lưu ý: Firebase yêu cầu composite index nếu kết hợp nhiều where (OR query).
    // Tạm thời để đơn giản cho Demo, ta lấy các giao dịch mà senderId = userId hoặc receiverId = userId
    // Firebase Firestore SDK mới hỗ trợ Filter.or
    return firestore
        .collection('transactions')
        .where(
          Filter.or(
            Filter('senderId', isEqualTo: userId),
            Filter('receiverId', isEqualTo: userId),
          ),
        )
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            // Handle timestamp serialization
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data(),
            );
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            } else if (data['timestamp'] == null) {
              data['timestamp'] = DateTime.now()
                  .toIso8601String(); // Fallback pending server time
            }
            return TransactionModel.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }
}
