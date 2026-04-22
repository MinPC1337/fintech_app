import 'package:equatable/equatable.dart';

class TransactionEntity extends Equatable {
  final String id;
  final String? fromWalletId;
  final String? toWalletId;
  final String? senderId;
  final String? receiverId;
  final double amount;
  final String categoryId;
  final DateTime timestamp;
  final String type;
  final String note;

  const TransactionEntity({
    required this.id,
    this.fromWalletId,
    this.toWalletId,
    this.senderId,
    this.receiverId,
    required this.amount,
    required this.categoryId,
    required this.timestamp,
    this.type = '',
    this.note = '',
  });

  @override
  List<Object?> get props => [
        id,
        fromWalletId,
        toWalletId,
        senderId,
        receiverId,
        amount,
        categoryId,
        timestamp,
        type,
        note,
      ];
}
