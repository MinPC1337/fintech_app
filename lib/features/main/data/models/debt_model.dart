import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.walletId,
    required super.transactionId,
    required super.lenderId,
    required super.borrowerId,
    required super.amount,
    required super.isSettled,
    super.createdAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      transactionId: json['transactionId'] ?? '',
      lenderId: json['lenderId'] ?? '',
      borrowerId: json['borrowerId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      isSettled: json['isSettled'] ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'transactionId': transactionId,
      'lenderId': lenderId,
      'borrowerId': borrowerId,
      'amount': amount,
      'isSettled': isSettled,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
