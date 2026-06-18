import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.ownerId,
    required super.members,
    required super.isPersonal,
    super.accentArgb,
    super.createdAt,
    super.status,
    super.closeApprovals,
    super.imageUrl,
    super.emoji,
    super.scheduledDeletionTime,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      ownerId: json['ownerId'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      isPersonal: json['isPersonal'] ?? false,
      accentArgb: json['accentArgb'] as int?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.tryParse(json['createdAt'].toString()))
          : null,
      status: json['status'] ?? 'active',
      closeApprovals: List<String>.from(json['closeApprovals'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      emoji: json['emoji'] as String?,
      scheduledDeletionTime: json['scheduledDeletionTime'] != null
          ? (json['scheduledDeletionTime'] is DateTime
              ? json['scheduledDeletionTime'] as DateTime
              : (json['scheduledDeletionTime'] is Timestamp
                  ? (json['scheduledDeletionTime'] as Timestamp).toDate()
                  : DateTime.tryParse(json['scheduledDeletionTime'].toString())))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'ownerId': ownerId,
      'members': members,
      'isPersonal': isPersonal,
      if (accentArgb != null) 'accentArgb': accentArgb,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      'status': status,
      'closeApprovals': closeApprovals,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (emoji != null) 'emoji': emoji,
      if (scheduledDeletionTime != null)
        'scheduledDeletionTime': scheduledDeletionTime!.toIso8601String(),
    };
  }
}
