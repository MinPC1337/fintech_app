import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';
import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';
import 'package:fintech_app/features/group_wallet/domain/entities/remind_debt_result.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';

abstract class GroupWalletRepository {
  // CRUD ví nhóm
  Future<WalletEntity> createGroupWallet(
    String name,
    String ownerId,
    int? accentArgb,
    String? imageUrl,
    String? emoji,
  );
  Stream<List<WalletEntity>> watchGroupWallets(String userId);
  Stream<WalletEntity?> watchGroupWalletById(String walletId);
  Future<void> closeGroupWallet(String walletId, String requesterId);
  Future<void> approveCloseGroupWallet(String walletId, String userId);
  Future<void> rejectCloseGroupWallet(String walletId, String userId);

  // Thành viên
  Future<void> inviteMember(String walletId, String senderId, String receiverEmail);
  Future<void> acceptInvitation(String invitationId, String userId);
  Future<void> rejectInvitation(String invitationId);
  Future<void> removeMember(String walletId, String memberId, String requesterId);
  Stream<List<InvitationEntity>> watchPendingInvitations(String userId);

  // Giao dịch ví nhóm
  Future<void> contributeToGroup(String walletId, String senderId, double amount);
  Future<void> withdrawFromGroup(String walletId, String requesterId, double amount, String note);
  Stream<List<TransactionEntity>> watchGroupTransactions(String walletId);

  // Chia tiền
  Future<void> splitExpense(String walletId, String payerId, double totalAmount, String note, List<String> participantIds);
  Stream<List<DebtEntity>> watchDebts(String walletId);
  Future<void> settleDebt(String debtId, String borrowerId);
  Future<RemindDebtResult> remindDebt(String debtId, String lenderId);

  // Aggregated overview
  Stream<List<TransactionEntity>> watchAllGroupTransactions(List<String> walletIds);
  Stream<List<DebtEntity>> watchMyUnsettledDebts(String userId);
  Future<Map<String, String>> getUserNames(List<String> userIds);
  Future<Map<String, Map<String, String>>> getUserProfiles(List<String> userIds);
}
