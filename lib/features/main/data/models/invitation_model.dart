import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';

class InvitationModel extends InvitationEntity {
  const InvitationModel({
    required super.id,
    required super.walletId,
    required super.senderId,
    required super.receiverEmail,
    required super.status,
    super.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? '',
      walletId: json['walletId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      status: _parseStatus(json['status']),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
    );
  }

  static InvitationStatus _parseStatus(dynamic value) {
    switch (value) {
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      default:
        return InvitationStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'senderId': senderId,
      'receiverEmail': receiverEmail,
      'status': status.name,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
