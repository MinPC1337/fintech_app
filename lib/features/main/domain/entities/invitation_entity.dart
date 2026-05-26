import 'package:equatable/equatable.dart';

enum InvitationStatus {
  pending,
  accepted,
  rejected,
}

class InvitationEntity extends Equatable {
  final String id;
  final String walletId;
  final String senderId;
  final String receiverEmail;
  final InvitationStatus status;
  final DateTime? createdAt;

  const InvitationEntity({
    required this.id,
    required this.walletId,
    required this.senderId,
    required this.receiverEmail,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        walletId,
        senderId,
        receiverEmail,
        status,
        createdAt,
      ];
}
