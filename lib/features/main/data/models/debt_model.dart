import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';

class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.transactionId,
    required super.lenderId,
    required super.borrowerId,
    required super.amount,
    required super.isSettled,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      lenderId: json['lenderId'] ?? '',
      borrowerId: json['borrowerId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      isSettled: json['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionId': transactionId,
      'lenderId': lenderId,
      'borrowerId': borrowerId,
      'amount': amount,
      'isSettled': isSettled,
    };
  }
}
