import 'package:equatable/equatable.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';
import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

abstract class GroupWalletState extends Equatable {
  const GroupWalletState();

  @override
  List<Object?> get props => [];
}

class GroupWalletInitial extends GroupWalletState {}

class GroupWalletLoading extends GroupWalletState {}

class GroupWalletFailure extends GroupWalletState {
  final String message;

  const GroupWalletFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class GroupWalletLoaded extends GroupWalletState {
  final List<WalletEntity> wallets;
  final WalletEntity? selectedWallet;
  final List<TransactionEntity> transactions;
  final List<DebtEntity> debts;
  final List<InvitationEntity> pendingInvitations;
  final bool isActionInProgress;
  final String? message;

  // Aggregated overview data
  final List<TransactionEntity> allRecentTransactions;
  final List<DebtEntity> myUnsettledDebts;
  final Map<String, String> memberNames;
  final Map<String, String> memberAvatars;

  const GroupWalletLoaded({
    required this.wallets,
    this.selectedWallet,
    required this.transactions,
    required this.debts,
    required this.pendingInvitations,
    this.isActionInProgress = false,
    this.message,
    this.allRecentTransactions = const [],
    this.myUnsettledDebts = const [],
    this.memberNames = const {},
    this.memberAvatars = const {},
  });

  @override
  List<Object?> get props => [
    wallets,
    selectedWallet,
    transactions,
    debts,
    pendingInvitations,
    isActionInProgress,
    message,
    allRecentTransactions,
    myUnsettledDebts,
    memberNames,
    memberAvatars,
  ];

  GroupWalletLoaded copyWith({
    List<WalletEntity>? wallets,
    WalletEntity? selectedWallet,
    List<TransactionEntity>? transactions,
    List<DebtEntity>? debts,
    List<InvitationEntity>? pendingInvitations,
    bool? isActionInProgress,
    String? message,
    List<TransactionEntity>? allRecentTransactions,
    List<DebtEntity>? myUnsettledDebts,
    Map<String, String>? memberNames,
    Map<String, String>? memberAvatars,
  }) {
    return GroupWalletLoaded(
      wallets: wallets ?? this.wallets,
      selectedWallet: selectedWallet ?? this.selectedWallet,
      transactions: transactions ?? this.transactions,
      debts: debts ?? this.debts,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
      message: message,
      allRecentTransactions:
          allRecentTransactions ?? this.allRecentTransactions,
      myUnsettledDebts: myUnsettledDebts ?? this.myUnsettledDebts,
      memberNames: memberNames ?? this.memberNames,
      memberAvatars: memberAvatars ?? this.memberAvatars,
    );
  }
}
