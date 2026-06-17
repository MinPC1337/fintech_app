import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String id;
  final String name;
  final double balance;
  final String ownerId;
  final List<String> members;
  final bool isPersonal;
  final int? accentArgb;
  final DateTime? createdAt;
  final String status; // "active" | "closed"
  final String? imageUrl;
  final String? emoji;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.ownerId,
    required this.members,
    required this.isPersonal,
    this.accentArgb,
    this.createdAt,
    this.status = 'active',
    this.imageUrl,
    this.emoji,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        balance,
        ownerId,
        members,
        isPersonal,
        accentArgb,
        createdAt,
        status,
        imageUrl,
        emoji,
      ];
}
