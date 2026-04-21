import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';

class InvitationModel extends InvitationEntity {
  const InvitationModel({
    required super.id,
    required super.walletId,
    required super.senderId,
    required super.receiverEmail,
    required super.status,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      status: json['status'] == 'accepted' 
          ? InvitationStatus.accepted 
          : InvitationStatus.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'senderId': senderId,
      'receiverEmail': receiverEmail,
      'status': status == InvitationStatus.accepted ? 'accepted' : 'pending',
    };
  }
}
