import 'package:equatable/equatable.dart';

class WalletEntity extends Equatable {
  final String id;
  final String name;
  final double balance;
  final String ownerId;
  final List<String> members;
  final bool isPersonal;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.ownerId,
    required this.members,
    required this.isPersonal,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        balance,
        ownerId,
        members,
        isPersonal,
      ];
}
