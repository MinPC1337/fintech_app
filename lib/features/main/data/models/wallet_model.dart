import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.name,
    required super.balance,
    required super.ownerId,
    required super.members,
    required super.isPersonal,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      ownerId: json['ownerId'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      isPersonal: json['isPersonal'] ?? false,
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
    };
  }
}
