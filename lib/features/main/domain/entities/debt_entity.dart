import 'package:equatable/equatable.dart';

class DebtEntity extends Equatable {
  final String id;
  final String transactionId;
  final String lenderId;
  final String borrowerId;
  final double amount;
  final bool isSettled;

  const DebtEntity({
    required this.id,
    required this.transactionId,
    required this.lenderId,
    required this.borrowerId,
    required this.amount,
    required this.isSettled,
  });

  @override
  List<Object?> get props => [
        id,
        transactionId,
        lenderId,
        borrowerId,
        amount,
        isSettled,
      ];
}
