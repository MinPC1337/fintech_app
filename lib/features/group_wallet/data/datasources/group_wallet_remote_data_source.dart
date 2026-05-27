import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../main/data/models/wallet_model.dart';
import '../../../main/data/models/transaction_model.dart';
import '../../../main/data/models/invitation_model.dart';
import '../../../main/data/models/debt_model.dart';

abstract class GroupWalletRemoteDataSource {
  Future<WalletModel> createGroupWallet(
    String name,
    String ownerId,
    int? accentArgb,
  );
  Stream<List<WalletModel>> watchGroupWallets(String userId);
  Stream<WalletModel?> watchGroupWalletById(String walletId);
  Future<void> closeGroupWallet(String walletId, String requesterId);

  Future<void> inviteMember(
    String walletId,
    String senderId,
    String receiverEmail,
  );
  Future<void> acceptInvitation(String invitationId, String userId);
  Future<void> rejectInvitation(String invitationId);
  Future<void> removeMember(
    String walletId,
    String memberId,
    String requesterId,
  );
  Stream<List<InvitationModel>> watchPendingInvitations(String userId);

  Future<void> contributeToGroup(
    String walletId,
    String senderId,
    double amount,
  );
  Future<void> withdrawFromGroup(
    String walletId,
    String requesterId,
    double amount,
    String note,
  );
  Stream<List<TransactionModel>> watchGroupTransactions(String walletId);

  Future<void> splitExpense(
    String walletId,
    String payerId,
    double totalAmount,
    String note,
    List<String> participantIds,
  );
  Stream<List<DebtModel>> watchDebts(String walletId);
  Future<void> settleDebt(String debtId, String borrowerId);
}

class GroupWalletRemoteDataSourceImpl implements GroupWalletRemoteDataSource {
  final FirebaseFirestore firestore;

  GroupWalletRemoteDataSourceImpl({required this.firestore});

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  Future<String> _getUserFullName(String uid) async {
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) return 'Người dùng';
      final name = doc.data()?['fullName'];
      if (name is String && name.trim().isNotEmpty) return name.trim();
    } catch (_) {}
    return 'Người dùng';
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _getPrimaryWalletDoc(
    String userId,
  ) async {
    final query = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first;
  }

  // ─────────────────────────────────────────────
  // CRUD Ví Nhóm
  // ─────────────────────────────────────────────

  @override
  Future<WalletModel> createGroupWallet(
    String name,
    String ownerId,
    int? accentArgb,
  ) async {
    final ref = firestore.collection('wallets').doc();
    final data = {
      'id': ref.id,
      'name': name,
      'balance': 0.0,
      'ownerId': ownerId,
      'members': [ownerId],
      'isPersonal': false,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'accentArgb': ?accentArgb,
    };
    await ref.set(data);
    debugPrint('[GROUP_WALLET] Created group wallet: ${ref.id}');
    return WalletModel(
      id: ref.id,
      name: name,
      balance: 0,
      ownerId: ownerId,
      members: [ownerId],
      isPersonal: false,
      accentArgb: accentArgb,
      createdAt: DateTime.now(),
      status: 'active',
    );
  }

  @override
  Stream<List<WalletModel>> watchGroupWallets(String userId) {
    return firestore
        .collection('wallets')
        .where('members', arrayContains: userId)
        .where('isPersonal', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }
            return WalletModel.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  @override
  Stream<WalletModel?> watchGroupWalletById(String walletId) {
    return firestore.collection('wallets').doc(walletId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data()!);
      if (data['createdAt'] is Timestamp) {
        data['createdAt'] = (data['createdAt'] as Timestamp)
            .toDate()
            .toIso8601String();
      }
      return WalletModel.fromJson({...data, 'id': doc.id});
    });
  }

  @override
  Future<void> closeGroupWallet(String walletId, String requesterId) async {
    final doc = await firestore.collection('wallets').doc(walletId).get();
    if (!doc.exists) throw Exception('Ví nhóm không tồn tại');
    if (doc.data()?['ownerId'] != requesterId) {
      throw Exception('Chỉ trưởng nhóm mới có thể đóng ví nhóm');
    }
    await firestore.collection('wallets').doc(walletId).update({
      'status': 'closed',
    });
  }

  // ─────────────────────────────────────────────
  // Thành viên
  // ─────────────────────────────────────────────

  @override
  Future<void> inviteMember(
    String walletId,
    String senderId,
    String receiverEmail,
  ) async {
    // Kiểm tra user tồn tại
    final userQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: receiverEmail)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) {
      throw Exception('Không tìm thấy người dùng với email này');
    }

    // Kiểm tra đã là member chưa
    final walletDoc = await firestore.collection('wallets').doc(walletId).get();
    final members = List<String>.from(walletDoc.data()?['members'] ?? []);
    final receiverUid = userQuery.docs.first.id;
    if (members.contains(receiverUid)) {
      throw Exception('Người dùng đã là thành viên của ví nhóm');
    }

    // Kiểm tra đã có invitation pending chưa
    final existingInvite = await firestore
        .collection('invitations')
        .where('walletId', isEqualTo: walletId)
        .where('receiverEmail', isEqualTo: receiverEmail)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existingInvite.docs.isNotEmpty) {
      throw Exception('Đã gửi lời mời cho người dùng này');
    }

    final senderDoc = await firestore.collection('users').doc(senderId).get();
    final senderEmail = senderDoc.data()?['email'] ?? '';
    final senderName = senderDoc.data()?['fullName'] ?? 'Người dùng';
    final walletName = walletDoc.data()?['name'] ?? 'Ví nhóm';

    // Tạo invitation
    final ref = firestore.collection('invitations').doc();
    await ref.set({
      'id': ref.id,
      'walletId': walletId,
      'walletName': walletName, // Lưu thêm tên ví để hiển thị cho người nhận
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverEmail': receiverEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Tạo notification cho người nhận
    final notifRef = firestore.collection('notifications').doc();
    await notifRef.set({
      'id': notifRef.id,
      'userId': receiverUid,
      'title': 'Lời mời ví nhóm',
      'body': '$senderName mời bạn tham gia ví nhóm "$walletName"',
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'type': 'invitation',
    });
  }

  @override
  Future<void> acceptInvitation(String invitationId, String userId) async {
    await firestore.runTransaction((transaction) async {
      final inviteRef = firestore.collection('invitations').doc(invitationId);
      final inviteSnap = await transaction.get(inviteRef);

      if (!inviteSnap.exists) throw Exception('Lời mời không tồn tại');
      if (inviteSnap.data()?['status'] != 'pending') {
        throw Exception('Lời mời đã được xử lý');
      }

      final walletId = inviteSnap.data()!['walletId'] as String;
      final walletRef = firestore.collection('wallets').doc(walletId);

      // Cập nhật invitation status
      transaction.update(inviteRef, {'status': 'accepted'});

      // Thêm user vào members
      transaction.update(walletRef, {
        'members': FieldValue.arrayUnion([userId]),
      });
    });
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    await firestore.collection('invitations').doc(invitationId).update({
      'status': 'rejected',
    });
  }

  @override
  Future<void> removeMember(
    String walletId,
    String memberId,
    String requesterId,
  ) async {
    final walletDoc = await firestore.collection('wallets').doc(walletId).get();
    if (!walletDoc.exists) throw Exception('Ví nhóm không tồn tại');
    if (walletDoc.data()?['ownerId'] != requesterId) {
      throw Exception('Chỉ trưởng nhóm mới có thể xoá thành viên');
    }
    if (memberId == requesterId) {
      throw Exception('Không thể tự xoá chính mình khỏi nhóm');
    }

    await firestore.collection('wallets').doc(walletId).update({
      'members': FieldValue.arrayRemove([memberId]),
    });
  }

  @override
  Stream<List<InvitationModel>> watchPendingInvitations(String userId) {
    // Tìm email của user hiện tại
    return firestore.collection('users').doc(userId).snapshots().asyncExpand((
      userDoc,
    ) {
      final email = userDoc.data()?['email'] as String?;
      if (email == null || email.isEmpty) {
        return Stream.value(<InvitationModel>[]);
      }
      return firestore
          .collection('invitations')
          .where('receiverEmail', isEqualTo: email)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] = (data['createdAt'] as Timestamp)
                    .toDate()
                    .toIso8601String();
              }
              return InvitationModel.fromJson({...data, 'id': doc.id});
            }).toList();
          });
    });
  }

  // ─────────────────────────────────────────────
  // Giao dịch ví nhóm
  // ─────────────────────────────────────────────

  @override
  Future<void> contributeToGroup(
    String walletId,
    String senderId,
    double amount,
  ) async {
    final senderWalletDoc = await _getPrimaryWalletDoc(senderId);
    if (senderWalletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của bạn');
    }

    final senderName = await _getUserFullName(senderId);

    await firestore.runTransaction((transaction) async {
      final senderSnap = await transaction.get(senderWalletDoc.reference);
      final groupRef = firestore.collection('wallets').doc(walletId);
      final groupSnap = await transaction.get(groupRef);

      if (!senderSnap.exists) throw Exception('Ví cá nhân không tồn tại');
      if (!groupSnap.exists) throw Exception('Ví nhóm không tồn tại');
      if (groupSnap.data()?['status'] == 'closed') {
        throw Exception('Ví nhóm đã đóng');
      }

      final senderBalance = (senderSnap.data()?['balance'] ?? 0).toDouble();
      if (senderBalance < amount) throw Exception('Số dư ví cá nhân không đủ');

      final groupBalance = (groupSnap.data()?['balance'] ?? 0).toDouble();
      final groupName = groupSnap.data()?['name'] ?? 'Ví nhóm';

      // Trừ ví cá nhân
      transaction.update(senderWalletDoc.reference, {
        'balance': senderBalance - amount,
      });

      // Cộng ví nhóm
      transaction.update(groupRef, {'balance': groupBalance + amount});

      // Ghi giao dịch Expense cho sender (ví cá nhân)
      final senderTxRef = firestore.collection('transactions').doc();
      transaction.set(senderTxRef, {
        'id': senderTxRef.id,
        'fromWalletId': senderWalletDoc.id,
        'toWalletId': walletId,
        'senderId': senderId,
        'userId': senderId,
        'amount': amount,
        'categoryId': 'group_contribute',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': 'Nạp vào quỹ nhóm "$groupName"',
        'walletId': walletId,
      });

      // Ghi giao dịch Income cho ví nhóm
      final groupTxRef = firestore.collection('transactions').doc();
      transaction.set(groupTxRef, {
        'id': groupTxRef.id,
        'fromWalletId': senderWalletDoc.id,
        'toWalletId': walletId,
        'senderId': senderId,
        'userId': senderId,
        'amount': amount,
        'categoryId': 'group_contribute',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Income',
        'note': '$senderName nạp vào quỹ',
        'walletId': walletId,
      });

      // Tạo notification
      final notifRef = firestore.collection('notifications').doc();
      transaction.set(notifRef, {
        'id': notifRef.id,
        'userId': senderId,
        'title': 'Nạp quỹ nhóm thành công',
        'body': 'Bạn đã nạp ${amount.toStringAsFixed(0)} VNĐ vào "$groupName".',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'transaction',
      });
    });
  }

  @override
  Future<void> withdrawFromGroup(
    String walletId,
    String requesterId,
    double amount,
    String note,
  ) async {
    final requesterWalletDoc = await _getPrimaryWalletDoc(requesterId);
    if (requesterWalletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của bạn');
    }

    await firestore.runTransaction((transaction) async {
      final groupRef = firestore.collection('wallets').doc(walletId);
      final groupSnap = await transaction.get(groupRef);
      final requesterSnap = await transaction.get(requesterWalletDoc.reference);

      if (!groupSnap.exists) throw Exception('Ví nhóm không tồn tại');
      if (groupSnap.data()?['status'] == 'closed') {
        throw Exception('Ví nhóm đã đóng');
      }
      if (groupSnap.data()?['ownerId'] != requesterId) {
        throw Exception('Chỉ trưởng nhóm mới có thể rút tiền');
      }

      final groupBalance = (groupSnap.data()?['balance'] ?? 0).toDouble();
      if (groupBalance < amount) throw Exception('Số dư ví nhóm không đủ');

      final requesterBalance = (requesterSnap.data()?['balance'] ?? 0)
          .toDouble();
      final groupName = groupSnap.data()?['name'] ?? 'Ví nhóm';

      // Trừ ví nhóm
      transaction.update(groupRef, {'balance': groupBalance - amount});

      // Cộng ví cá nhân
      transaction.update(requesterWalletDoc.reference, {
        'balance': requesterBalance + amount,
      });

      // Ghi giao dịch
      final txRef = firestore.collection('transactions').doc();
      transaction.set(txRef, {
        'id': txRef.id,
        'fromWalletId': walletId,
        'toWalletId': requesterWalletDoc.id,
        'senderId': requesterId,
        'userId': requesterId,
        'amount': amount,
        'categoryId': 'group_withdraw',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': note.isNotEmpty ? note : 'Rút tiền từ "$groupName"',
        'walletId': walletId,
      });

      // Notification
      final notifRef = firestore.collection('notifications').doc();
      transaction.set(notifRef, {
        'id': notifRef.id,
        'userId': requesterId,
        'title': 'Rút tiền quỹ nhóm',
        'body': 'Đã rút ${amount.toStringAsFixed(0)} VNĐ từ "$groupName".',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'transaction',
      });
    });
  }

  List<TransactionModel> _mapTransactionsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) {
      final data = Map<String, dynamic>.from(doc.data());
      if (data['timestamp'] is Timestamp) {
        data['timestamp'] = (data['timestamp'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else if (data['timestamp'] == null) {
        data['timestamp'] = DateTime.now().toIso8601String();
      }
      return TransactionModel.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  @override
  Stream<List<TransactionModel>> watchGroupTransactions(String walletId) {
    final transactionsCollection = firestore.collection('transactions');
    final streams = [
      transactionsCollection
          .where('walletId', isEqualTo: walletId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      transactionsCollection
          .where('fromWalletId', isEqualTo: walletId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      transactionsCollection
          .where('toWalletId', isEqualTo: walletId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
    ];

    late final StreamController<List<TransactionModel>> controller;
    controller = StreamController<List<TransactionModel>>(
      onListen: () {
        final latestResults = <int, List<TransactionModel>>{};
        final subscriptions =
            <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

        void emitCombined() {
          final combined = latestResults.values
              .expand((transactions) => transactions)
              .toList();
          final uniqueTransactions = <String, TransactionModel>{};
          for (final transaction in combined) {
            uniqueTransactions[transaction.id] = transaction;
          }
          final sortedTransactions = uniqueTransactions.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          if (!controller.isClosed) {
            controller.add(sortedTransactions);
          }
        }

        for (var index = 0; index < streams.length; index++) {
          final subscription = streams[index].listen((snapshot) {
            latestResults[index] = _mapTransactionsFromSnapshot(snapshot);
            emitCombined();
          }, onError: controller.addError);
          subscriptions.add(subscription);
        }

        controller.onCancel = () {
          for (final subscription in subscriptions) {
            subscription.cancel();
          }
        };
      },
      onPause: () {},
      onResume: () {},
      onCancel: () {},
    );

    return controller.stream;
  }

  // ─────────────────────────────────────────────
  // Chia tiền
  // ─────────────────────────────────────────────

  @override
  Future<void> splitExpense(
    String walletId,
    String payerId,
    double totalAmount,
    String note,
    List<String> participantIds,
  ) async {
    final sharePerPerson = totalAmount / participantIds.length;

    await firestore.runTransaction((transaction) async {
      // Tạo transaction ghi nhận chi tiêu nhóm
      final txRef = firestore.collection('transactions').doc();
      transaction.set(txRef, {
        'id': txRef.id,
        'senderId': payerId,
        'userId': payerId,
        'amount': totalAmount,
        'categoryId': 'group_split',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': note.isNotEmpty ? note : 'Chia tiền nhóm',
        'walletId': walletId,
      });

      // Tạo debt cho mỗi participant (trừ payer)
      for (final participantId in participantIds) {
        if (participantId == payerId) continue;

        final debtRef = firestore.collection('debts').doc();
        transaction.set(debtRef, {
          'id': debtRef.id,
          'walletId': walletId,
          'transactionId': txRef.id,
          'lenderId': payerId,
          'borrowerId': participantId,
          'amount': sharePerPerson,
          'isSettled': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Notification cho borrower
        final notifRef = firestore.collection('notifications').doc();
        final payerName = await _getUserFullName(payerId);
        transaction.set(notifRef, {
          'id': notifRef.id,
          'userId': participantId,
          'title': 'Chia tiền nhóm',
          'body':
              '$payerName chia tiền: bạn cần trả ${sharePerPerson.toStringAsFixed(0)} VNĐ',
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
          'type': 'debt',
        });
      }
    });
  }

  @override
  Stream<List<DebtModel>> watchDebts(String walletId) {
    return firestore
        .collection('debts')
        .where('walletId', isEqualTo: walletId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            if (data['createdAt'] is Timestamp) {
              data['createdAt'] = (data['createdAt'] as Timestamp)
                  .toDate()
                  .toIso8601String();
            }
            return DebtModel.fromJson({...data, 'id': doc.id});
          }).toList();
        });
  }

  @override
  Future<void> settleDebt(String debtId, String borrowerId) async {
    final debtDoc = await firestore.collection('debts').doc(debtId).get();
    if (!debtDoc.exists) throw Exception('Khoản nợ không tồn tại');

    final debtData = debtDoc.data()!;
    if (debtData['borrowerId'] != borrowerId) {
      throw Exception('Bạn không phải người nợ');
    }
    if (debtData['isSettled'] == true) {
      throw Exception('Khoản nợ đã được thanh toán');
    }

    final lenderId = debtData['lenderId'] as String;
    final amount = (debtData['amount'] ?? 0).toDouble();

    // Tìm ví cá nhân của cả hai
    final borrowerWalletDoc = await _getPrimaryWalletDoc(borrowerId);
    final lenderWalletDoc = await _getPrimaryWalletDoc(lenderId);
    if (borrowerWalletDoc == null) {
      throw Exception('Không tìm thấy ví cá nhân của bạn');
    }
    if (lenderWalletDoc == null) {
      throw Exception('Không tìm thấy ví của người cho nợ');
    }

    final borrowerName = await _getUserFullName(borrowerId);
    final lenderName = await _getUserFullName(lenderId);

    await firestore.runTransaction((transaction) async {
      final borrowerSnap = await transaction.get(borrowerWalletDoc.reference);
      final lenderSnap = await transaction.get(lenderWalletDoc.reference);

      final borrowerBalance = (borrowerSnap.data()?['balance'] ?? 0).toDouble();
      if (borrowerBalance < amount) {
        throw Exception('Số dư không đủ để thanh toán nợ');
      }

      final lenderBalance = (lenderSnap.data()?['balance'] ?? 0).toDouble();

      // Trừ tiền borrower
      transaction.update(borrowerWalletDoc.reference, {
        'balance': borrowerBalance - amount,
      });

      // Cộng tiền lender
      transaction.update(lenderWalletDoc.reference, {
        'balance': lenderBalance + amount,
      });

      // Đánh dấu debt đã settle
      transaction.update(firestore.collection('debts').doc(debtId), {
        'isSettled': true,
      });

      // Ghi transaction cho borrower (Expense)
      final borrowerTxRef = firestore.collection('transactions').doc();
      transaction.set(borrowerTxRef, {
        'id': borrowerTxRef.id,
        'fromWalletId': borrowerWalletDoc.id,
        'toWalletId': lenderWalletDoc.id,
        'senderId': borrowerId,
        'receiverId': lenderId,
        'userId': borrowerId,
        'amount': amount,
        'categoryId': 'debt_settle',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Expense',
        'note': 'Thanh toán nợ cho $lenderName',
      });

      // Ghi transaction cho lender (Income)
      final lenderTxRef = firestore.collection('transactions').doc();
      transaction.set(lenderTxRef, {
        'id': lenderTxRef.id,
        'fromWalletId': borrowerWalletDoc.id,
        'toWalletId': lenderWalletDoc.id,
        'senderId': borrowerId,
        'receiverId': lenderId,
        'userId': lenderId,
        'amount': amount,
        'categoryId': 'debt_settle',
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'Income',
        'note': '$borrowerName thanh toán nợ',
      });

      // Notifications
      final borrowerNotif = firestore.collection('notifications').doc();
      transaction.set(borrowerNotif, {
        'id': borrowerNotif.id,
        'userId': borrowerId,
        'title': 'Thanh toán nợ thành công',
        'body':
            'Đã thanh toán ${amount.toStringAsFixed(0)} VNĐ cho $lenderName.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'transaction',
      });

      final lenderNotif = firestore.collection('notifications').doc();
      transaction.set(lenderNotif, {
        'id': lenderNotif.id,
        'userId': lenderId,
        'title': 'Nhận thanh toán nợ',
        'body': '$borrowerName đã thanh toán ${amount.toStringAsFixed(0)} VNĐ.',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'transaction',
      });
    });
  }
}
