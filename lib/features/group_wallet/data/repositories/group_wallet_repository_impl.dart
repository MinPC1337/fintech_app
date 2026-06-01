import 'package:fintech_app/features/group_wallet/data/datasources/group_wallet_remote_data_source.dart';
import 'package:fintech_app/features/group_wallet/domain/entities/remind_debt_result.dart';
import 'package:fintech_app/features/group_wallet/domain/repositories/group_wallet_repository.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';
import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';

class GroupWalletRepositoryImpl implements GroupWalletRepository {
  final GroupWalletRemoteDataSource remoteDataSource;

  GroupWalletRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> acceptInvitation(String invitationId, String userId) async {
    await remoteDataSource.acceptInvitation(invitationId, userId);
  }

  @override
  Future<WalletEntity> createGroupWallet(
    String name,
    String ownerId,
    int? accentArgb,
  ) async {
    return await remoteDataSource.createGroupWallet(name, ownerId, accentArgb);
  }

  @override
  Future<void> closeGroupWallet(String walletId, String requesterId) async {
    await remoteDataSource.closeGroupWallet(walletId, requesterId);
  }

  @override
  Future<void> contributeToGroup(
    String walletId,
    String senderId,
    double amount,
  ) async {
    await remoteDataSource.contributeToGroup(walletId, senderId, amount);
  }

  @override
  Stream<List<DebtEntity>> watchDebts(String walletId) {
    return remoteDataSource.watchDebts(walletId);
  }

  @override
  Stream<List<InvitationEntity>> watchPendingInvitations(String userId) {
    return remoteDataSource.watchPendingInvitations(userId);
  }

  @override
  Stream<List<TransactionEntity>> watchGroupTransactions(String walletId) {
    return remoteDataSource.watchGroupTransactions(walletId);
  }

  @override
  Stream<WalletEntity?> watchGroupWalletById(String walletId) {
    return remoteDataSource.watchGroupWalletById(walletId);
  }

  @override
  Stream<List<WalletEntity>> watchGroupWallets(String userId) {
    return remoteDataSource.watchGroupWallets(userId);
  }

  @override
  Future<void> inviteMember(
    String walletId,
    String senderId,
    String receiverEmail,
  ) async {
    await remoteDataSource.inviteMember(walletId, senderId, receiverEmail);
  }

  @override
  Future<void> rejectInvitation(String invitationId) async {
    await remoteDataSource.rejectInvitation(invitationId);
  }

  @override
  Future<void> removeMember(
    String walletId,
    String memberId,
    String requesterId,
  ) async {
    await remoteDataSource.removeMember(walletId, memberId, requesterId);
  }

  @override
  Future<void> settleDebt(String debtId, String borrowerId) async {
    await remoteDataSource.settleDebt(debtId, borrowerId);
  }

  @override
  Future<RemindDebtResult> remindDebt(String debtId, String lenderId) async {
    return remoteDataSource.remindDebt(debtId, lenderId);
  }

  @override
  Future<void> withdrawFromGroup(
    String walletId,
    String requesterId,
    double amount,
    String note,
  ) async {
    await remoteDataSource.withdrawFromGroup(
      walletId,
      requesterId,
      amount,
      note,
    );
  }

  @override
  Future<void> splitExpense(
    String walletId,
    String payerId,
    double totalAmount,
    String note,
    List<String> participantIds,
  ) async {
    await remoteDataSource.splitExpense(
      walletId,
      payerId,
      totalAmount,
      note,
      participantIds,
    );
  }
}
