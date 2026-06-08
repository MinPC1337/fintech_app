import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/push_api_client.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

abstract class WalletRemoteDataSource {
  Future<void> depositToWallet(String receiverUid, double amount);
  Future<WalletModel?> getPrimaryWallet(String userId);
  Stream<WalletModel?> getPrimaryWalletStream(String userId);
  Future<void> transferOut(
    String senderUid,
    double amount,
    String targetPhone,
    String categoryId,
  );
  Stream<List<TransactionModel>> getTransactionsStream(String userId);

  /// Chuyển tiền nội bộ từ user này sang user khác trong app
  Future<void> transferToUser(
    String senderUid,
    String receiverUid,
    double amount,
    String categoryId,
  );
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final FirebaseFirestore firestore;
  final PushApiClient pushApiClient;

  WalletRemoteDataSourceImpl({
    required this.firestore,
    required this.pushApiClient,
  });

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

  /// Tên hiển thị từ `users/{uid}.fullName` (đồng bộ với profile app).
  Future<String> _getUserFullName(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) return 'Người dùng';
      final name = doc.data()?['fullName'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {
      // Bỏ qua lỗi mạng / quyền đọc — fallback bên dưới
    }
    return 'Người dùng';
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

      // 3. Tạo bản ghi thông báo
      final notifRef = firestore.collection('notifications').doc();
      transaction.set(notifRef, {
        'id': notifRef.id,
        'userId': receiverUid,
        'title': 'Nạp tiền thành công',
        'body': 'Bạn vừa nạp ${amount.toStringAsFixed(0)} VNĐ vào ví từ MoMo.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'transaction',
      });
    });

    try {
      await pushApiClient.sendPush(
        userId: receiverUid,
        title: 'Nạp tiền thành công',
        body: 'Bạn vừa nạp ${amount.toStringAsFixed(0)} VNĐ vào ví từ MoMo.',
        type: 'transaction',
      );
    } catch (e) {
      debugPrint('Failed to send push notification: $e');
    }
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
    String categoryId,
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
        'categoryId': categoryId,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': 'Chuyển khoản đến MoMo $targetPhone',
      };
      transaction.set(txRef, txData);

      // 3. Tạo bản ghi thông báo
      final notifRef = firestore.collection('notifications').doc();
      transaction.set(notifRef, {
        'id': notifRef.id,
        'userId': senderUid,
        'title': 'Rút tiền thành công',
        'body':
            'Giao dịch rút ${amount.toStringAsFixed(0)} VNĐ về số $targetPhone đã hoàn tất.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'transaction',
      });
    });

    try {
      await pushApiClient.sendPush(
        userId: senderUid,
        title: 'Rút tiền thành công',
        body:
            'Giao dịch rút ${amount.toStringAsFixed(0)} VNĐ về số $targetPhone đã hoàn tất.',
        type: 'transaction',
      );
    } catch (e) {
      debugPrint('Failed to send push notification: $e');
    }
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
            final Map<String, dynamic> data = Map<String, dynamic>.from(
              doc.data(),
            );
            if (data['timestamp'] is Timestamp) {
              data['timestamp'] = (data['timestamp'] as Timestamp)
                  .toDate()
                  .toIso8601String();
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
    String targetAccountNumber,
    double amount,
    String categoryId,
  ) async {
    // 1. Tìm receiverUid dựa trên Số tài khoản
    final userQuery = await firestore
        .collection('users')
        .where('accountNumber', isEqualTo: targetAccountNumber)
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) {
      throw Exception('Không tìm thấy người nhận với số tài khoản này');
    }
    final receiverUid = userQuery.docs.first.id;

    if (receiverUid == senderUid) {
      throw Exception('Không thể chuyển tiền cho chính mình');
    }

    // 2. Tìm ví chính của sender và receiver
    final senderWalletDoc = await _getPrimaryWalletDoc(senderUid);
    if (senderWalletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của bạn');
    }

    final receiverWalletDoc = await _getPrimaryWalletDoc(receiverUid);
    if (receiverWalletDoc == null) {
      throw Exception('Không tìm thấy ví của người nhận.');
    }

    final senderName = await _getUserFullName(senderUid);
    final receiverName = await _getUserFullName(receiverUid);

    // 2. Chạy Firestore Transaction nguyên tử
    debugPrint(
      '[DB_UPDATE] Starting transaction: $senderUid -> $receiverUid amount: $amount',
    );
    await firestore
        .runTransaction((transaction) async {
          final senderSnap = await transaction.get(senderWalletDoc.reference);
          final receiverSnap = await transaction.get(
            receiverWalletDoc.reference,
          );

          if (!senderSnap.exists || !receiverSnap.exists) {
            throw Exception('Ví không tồn tại');
          }

          final senderBalance = (senderSnap.data()?['balance'] ?? 0).toDouble();
          if (senderBalance < amount) {
            throw Exception('Số dư không đủ để thực hiện giao dịch');
          }

          final receiverBalance = (receiverSnap.data()?['balance'] ?? 0)
              .toDouble();

          // Cập nhật số dư cả hai ví
          transaction.update(senderWalletDoc.reference, {
            'balance': senderBalance - amount,
          });
          transaction.update(receiverWalletDoc.reference, {
            'balance': receiverBalance + amount,
          });

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
            'categoryId': categoryId,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'Expense',
            'note': 'Chuyển tiền đến $receiverName',
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
            'note': 'Nhận tiền từ $senderName',
          });

          // 4. Tạo thông báo cho cả hai bên
          final senderNotifRef = firestore.collection('notifications').doc();
          transaction.set(senderNotifRef, {
            'id': senderNotifRef.id,
            'userId': senderUid,
            'title': 'Chuyển tiền thành công',
            'body':
                'Bạn đã chuyển ${amount.toStringAsFixed(0)} VNĐ đến $receiverName.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'transaction',
          });

          final receiverNotifRef = firestore.collection('notifications').doc();
          transaction.set(receiverNotifRef, {
            'id': receiverNotifRef.id,
            'userId': receiverUid,
            'title': 'Nhận tiền thành công',
            'body':
                'Bạn vừa nhận được ${amount.toStringAsFixed(0)} VNĐ từ $senderName.',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'type': 'transaction',
          });
        })
        .then((_) async {
          debugPrint('[DB_UPDATE] Transaction committed successfully.');
          try {
            await pushApiClient.sendPush(
              userId: receiverUid,
              title: 'Nhận tiền thành công',
              body:
                  'Bạn vừa nhận được ${amount.toStringAsFixed(0)} VNĐ từ $senderName.',
              type: 'transaction',
            );
          } catch (e) {
            debugPrint('Failed to send push notification: $e');
          }
        });
  }
}
