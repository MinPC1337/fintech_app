import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    super.fromWalletId,
    super.toWalletId,
    super.senderId,
    super.receiverId,
    required super.amount,
    required super.categoryId,
    required super.timestamp,
    super.type,
    super.note,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      fromWalletId: json['fromWalletId'],
      toWalletId: json['toWalletId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      amount: (json['amount'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'].toString())
          : DateTime.now(),
      type: json['type'] ?? '',
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (fromWalletId != null) 'fromWalletId': fromWalletId,
      if (toWalletId != null) 'toWalletId': toWalletId,
      if (senderId != null) 'senderId': senderId,
      if (receiverId != null) 'receiverId': receiverId,
      'amount': amount,
      'categoryId': categoryId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
