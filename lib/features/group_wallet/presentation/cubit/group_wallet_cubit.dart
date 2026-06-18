import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/accept_invitation_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/close_group_wallet_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/approve_close_group_wallet_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/reject_close_group_wallet_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/contribute_to_group_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/create_group_wallet_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/invite_member_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/reject_invitation_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/remind_debt_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/remove_member_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/settle_debt_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/split_expense_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_debts_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_group_transactions_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_group_wallet_detail_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_group_wallets_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_pending_invitations_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/withdraw_from_group_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_all_group_transactions_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/usecases/watch_my_unsettled_debts_usecase.dart';
import 'package:fintech_app/features/group_wallet/domain/repositories/group_wallet_repository.dart';
import 'package:fintech_app/features/main/domain/entities/debt_entity.dart';
import 'package:fintech_app/features/main/domain/entities/invitation_entity.dart';
import 'package:fintech_app/features/main/domain/entities/transaction_entity.dart';
import 'package:fintech_app/features/main/domain/entities/wallet_entity.dart';
import 'package:fintech_app/core/utils/push_debug.dart';
import 'package:fintech_app/features/group_wallet/presentation/cubit/group_wallet_state.dart';

class GroupWalletCubit extends Cubit<GroupWalletState> {
  GroupWalletCubit({
    required this.createGroupWalletUseCase,
    required this.watchGroupWalletsUseCase,
    required this.watchGroupWalletDetailUseCase,
    required this.closeGroupWalletUseCase,
    required this.approveCloseGroupWalletUseCase,
    required this.rejectCloseGroupWalletUseCase,
    required this.inviteMemberUseCase,
    required this.acceptInvitationUseCase,
    required this.rejectInvitationUseCase,
    required this.removeMemberUseCase,
    required this.contributeToGroupUseCase,
    required this.withdrawFromGroupUseCase,
    required this.splitExpenseUseCase,
    required this.settleDebtUseCase,
    required this.remindDebtUseCase,
    required this.watchGroupTransactionsUseCase,
    required this.watchDebtsUseCase,
    required this.watchPendingInvitationsUseCase,
    required this.watchAllGroupTransactionsUseCase,
    required this.watchMyUnsettledDebtsUseCase,
    required this.groupWalletRepository,
  }) : super(GroupWalletInitial());

  final CreateGroupWalletUseCase createGroupWalletUseCase;
  final WatchGroupWalletsUseCase watchGroupWalletsUseCase;
  final WatchGroupWalletDetailUseCase watchGroupWalletDetailUseCase;
  final CloseGroupWalletUseCase closeGroupWalletUseCase;
  final ApproveCloseGroupWalletUseCase approveCloseGroupWalletUseCase;
  final RejectCloseGroupWalletUseCase rejectCloseGroupWalletUseCase;
  final InviteMemberUseCase inviteMemberUseCase;
  final AcceptInvitationUseCase acceptInvitationUseCase;
  final RejectInvitationUseCase rejectInvitationUseCase;
  final RemoveMemberUseCase removeMemberUseCase;
  final ContributeToGroupUseCase contributeToGroupUseCase;
  final WithdrawFromGroupUseCase withdrawFromGroupUseCase;
  final SplitExpenseUseCase splitExpenseUseCase;
  final SettleDebtUseCase settleDebtUseCase;
  final RemindDebtUseCase remindDebtUseCase;
  final WatchGroupTransactionsUseCase watchGroupTransactionsUseCase;
  final WatchDebtsUseCase watchDebtsUseCase;
  final WatchPendingInvitationsUseCase watchPendingInvitationsUseCase;
  final WatchAllGroupTransactionsUseCase watchAllGroupTransactionsUseCase;
  final WatchMyUnsettledDebtsUseCase watchMyUnsettledDebtsUseCase;
  final GroupWalletRepository groupWalletRepository;

  StreamSubscription<List<WalletEntity>>? _walletsSubscription;
  StreamSubscription<WalletEntity?>? _walletDetailSubscription;
  StreamSubscription<List<TransactionEntity>>? _transactionsSubscription;
  StreamSubscription<List<DebtEntity>>? _debtsSubscription;
  StreamSubscription<List<InvitationEntity>>? _pendingInvitationsSubscription;
  StreamSubscription<List<TransactionEntity>>? _allTransactionsSubscription;
  StreamSubscription<List<DebtEntity>>? _myDebtsSubscription;

  String? _userId;
  String? _selectedWalletId;

  final List<WalletEntity> _wallets = [];
  WalletEntity? _selectedWallet;
  final List<TransactionEntity> _transactions = [];
  final List<DebtEntity> _debts = [];
  final List<InvitationEntity> _pendingInvitations = [];
  bool _isActionInProgress = false;

  // Aggregated overview data
  List<TransactionEntity> _allRecentTransactions = [];
  List<DebtEntity> _myUnsettledDebts = [];
  final Map<String, String> _memberNames = {};
  final Map<String, String> _memberAvatars = {};

  void start(String userId) {
    _userId = userId;
    emit(GroupWalletLoading());
    _walletsSubscription?.cancel();
    _pendingInvitationsSubscription?.cancel();
    _myDebtsSubscription?.cancel();

    _walletsSubscription = watchGroupWalletsUseCase(userId).listen(
      (wallets) {
        final oldWalletIds = _wallets.map((w) => w.id).toSet();
        _wallets
          ..clear()
          ..addAll(wallets);
        if (_selectedWalletId != null &&
            !_wallets.any((w) => w.id == _selectedWalletId)) {
          _selectedWalletId = null;
          _selectedWallet = null;
          _cancelDetailsSubscriptions();
        }

        // Refresh aggregate subscriptions when wallet list changes
        final newWalletIds = wallets.map((w) => w.id).toSet();
        if (!_setEquals(oldWalletIds, newWalletIds)) {
          _refreshAllTransactionsSubscription(newWalletIds.toList());
        }

        // Resolve member names
        _resolveMemberNames(wallets);

        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(GroupWalletFailure(error.toString()));
      },
    );

    _pendingInvitationsSubscription = watchPendingInvitationsUseCase(userId)
        .listen(
          (invites) {
            _pendingInvitations
              ..clear()
              ..addAll(invites);
            _emitLoaded();
          },
          onError: (Object error, StackTrace stackTrace) {
            emit(GroupWalletFailure(error.toString()));
          },
        );

    // Watch my unsettled debts across all wallets
    _myDebtsSubscription = watchMyUnsettledDebtsUseCase(userId).listen(
      (debts) {
        _myUnsettledDebts = debts;
        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        // Non-critical: log but don't fail
      },
    );
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }

  void _refreshAllTransactionsSubscription(List<String> walletIds) {
    _allTransactionsSubscription?.cancel();
    if (walletIds.isEmpty) {
      _allRecentTransactions = [];
      return;
    }
    _allTransactionsSubscription = watchAllGroupTransactionsUseCase(walletIds)
        .listen(
          (txns) {
            _allRecentTransactions = txns;
            _emitLoaded();
          },
          onError: (Object error, StackTrace stackTrace) {
            // Non-critical
          },
        );
  }

  Future<void> _resolveMemberNames(List<WalletEntity> wallets) async {
    final allMemberIds = <String>{};
    for (final w in wallets) {
      allMemberIds.addAll(w.members);
    }

    // Only resolve names we don't have yet
    final unknownIds = allMemberIds
        .where((id) => !_memberNames.containsKey(id))
        .toList();
    if (unknownIds.isEmpty) return;

    try {
      final newProfiles = await groupWalletRepository.getUserProfiles(
        unknownIds,
      );
      for (final entry in newProfiles.entries) {
        _memberNames[entry.key] = entry.value['name']!;
        _memberAvatars[entry.key] = entry.value['avatarUrl'] ?? '';
      }
      _emitLoaded();
    } catch (_) {
      // Non-critical
    }
  }

  void selectWallet(String walletId) {
    if (_selectedWalletId == walletId) {
      return;
    }
    _selectedWalletId = walletId;
    _listenSelectedWallet(walletId);
    _listenTransactions(walletId);
    _listenDebts(walletId);
    _emitLoaded();
  }

  Future<bool> createGroupWallet(String name, int accentArgb, {String? imageUrl, String? emoji}) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await createGroupWalletUseCase(name, _userId!, accentArgb, imageUrl, emoji);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (wallet) {
        _selectedWalletId = wallet.id;
        _setMessage('Tạo ví nhóm thành công');
        selectWallet(wallet.id);
        return true;
      },
    );
  }

  Future<bool> inviteMember(String walletId, String receiverEmail) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await inviteMemberUseCase(walletId, _userId!, receiverEmail);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Gửi lời mời thành công');
        return true;
      },
    );
  }

  Future<bool> acceptInvitation(String invitationId) async {
    _setActionInProgress(true);
    final result = await acceptInvitationUseCase(invitationId, _userId ?? '');
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Đã chấp nhận lời mời');
        return true;
      },
    );
  }

  Future<bool> rejectInvitation(String invitationId) async {
    _setActionInProgress(true);
    final result = await rejectInvitationUseCase(invitationId);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Đã từ chối lời mời');
        return true;
      },
    );
  }

  Future<bool> contributeToGroup(String walletId, double amount) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await contributeToGroupUseCase(walletId, _userId!, amount);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Nạp quỹ nhóm thành công');
        return true;
      },
    );
  }

  Future<bool> withdrawFromGroup(
    String walletId,
    double amount,
    String note,
  ) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await withdrawFromGroupUseCase(
      walletId,
      _userId!,
      amount,
      note,
    );
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Rút tiền thành công');
        return true;
      },
    );
  }

  Future<bool> splitExpense(
    String walletId,
    double totalAmount,
    String note,
    List<String> participantIds,
  ) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await splitExpenseUseCase(
      walletId,
      _userId!,
      totalAmount,
      note,
      participantIds,
    );
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Chia tiền nhóm thành công');
        return true;
      },
    );
  }

  Future<bool> settleDebt(String debtId) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await settleDebtUseCase(debtId, _userId!);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Thanh toán nợ thành công');
        return true;
      },
    );
  }

  Future<bool> remindDebt(String debtId) async {
    if (_userId == null) return false;
    PushDebug.log('UI Nhắc nợ tapped', 'debtId=$debtId');
    _setActionInProgress(true);
    final result = await remindDebtUseCase(debtId, _userId!);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        PushDebug.fail('UI Nhắc nợ', failure.message);
        _setMessage(failure.message);
        return false;
      },
      (_) {
        PushDebug.ok('UI Nhắc nợ', 'thành công — xem log [Push] phía trên');
        _setMessage('Đã gửi nhắc nợ');
        return true;
      },
    );
  }

  Future<bool> closeGroupWallet(String walletId) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await closeGroupWalletUseCase(walletId, _userId!);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Đã gửi yêu cầu đóng ví nhóm (hoặc đã đóng nếu chỉ có 1 người)');
        return true;
      },
    );
  }

  Future<bool> approveCloseGroupWallet(String walletId) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await approveCloseGroupWalletUseCase(walletId, _userId!);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Đã đồng ý đóng ví nhóm');
        return true;
      },
    );
  }

  Future<bool> rejectCloseGroupWallet(String walletId) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await rejectCloseGroupWalletUseCase(walletId, _userId!);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Đã từ chối đóng ví nhóm');
        return true;
      },
    );
  }

  Future<bool> removeMember(String walletId, String memberId) async {
    if (_userId == null) return false;
    _setActionInProgress(true);
    final result = await removeMemberUseCase(walletId, memberId, _userId!);
    _setActionInProgress(false);
    return result.fold(
      (failure) {
        _setMessage(failure.message);
        return false;
      },
      (_) {
        _setMessage('Đã xoá thành viên');
        return true;
      },
    );
  }

  void dismissMessage() {
    final current = state;
    if (current is GroupWalletLoaded && current.message != null) {
      emit(current.copyWith(message: null));
    }
  }

  void _listenSelectedWallet(String walletId) {
    _walletDetailSubscription?.cancel();
    _walletDetailSubscription = watchGroupWalletDetailUseCase(walletId).listen(
      (wallet) {
        _selectedWallet = wallet;
        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(GroupWalletFailure(error.toString()));
      },
    );
  }

  void _listenTransactions(String walletId) {
    _transactionsSubscription?.cancel();
    _transactionsSubscription = watchGroupTransactionsUseCase(walletId).listen(
      (transactions) {
        _transactions
          ..clear()
          ..addAll(transactions);
        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(GroupWalletFailure(error.toString()));
      },
    );
  }

  void _listenDebts(String walletId) {
    _debtsSubscription?.cancel();
    _debtsSubscription = watchDebtsUseCase(walletId).listen(
      (debts) {
        _debts
          ..clear()
          ..addAll(debts);
        _emitLoaded();
      },
      onError: (Object error, StackTrace stackTrace) {
        emit(GroupWalletFailure(error.toString()));
      },
    );
  }

  void _emitLoaded({String? message}) {
    emit(
      GroupWalletLoaded(
        wallets: List.unmodifiable(_wallets),
        selectedWallet: _selectedWallet,
        transactions: List.unmodifiable(_transactions),
        debts: List.unmodifiable(_debts),
        pendingInvitations: List.unmodifiable(_pendingInvitations),
        isActionInProgress: _isActionInProgress,
        message: message,
        allRecentTransactions: List.unmodifiable(_allRecentTransactions),
        myUnsettledDebts: List.unmodifiable(_myUnsettledDebts),
        memberNames: Map.unmodifiable(_memberNames),
        memberAvatars: Map.unmodifiable(_memberAvatars),
      ),
    );
  }

  void _cancelDetailsSubscriptions() {
    _walletDetailSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _debtsSubscription?.cancel();
    _walletDetailSubscription = null;
    _transactionsSubscription = null;
    _debtsSubscription = null;
    _selectedWallet = null;
    _transactions.clear();
    _debts.clear();
  }

  void _setActionInProgress(bool value) {
    _isActionInProgress = value;
    _emitLoaded();
  }

  void _setMessage(String message) {
    _emitLoaded(message: message);
  }

  @override
  Future<void> close() {
    _walletsSubscription?.cancel();
    _walletDetailSubscription?.cancel();
    _transactionsSubscription?.cancel();
    _debtsSubscription?.cancel();
    _pendingInvitationsSubscription?.cancel();
    _allTransactionsSubscription?.cancel();
    _myDebtsSubscription?.cancel();
    return super.close();
  }
}
