import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/usecases/get_primary_wallet_stream_usecase.dart';
import '../../../../core/errors/failures.dart';
import 'budget_state.dart';

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit({
    required GetPrimaryWalletStreamUseCase getPrimaryWalletStreamUseCase,
    required BudgetRepository budgetRepository,
  }) : _getPrimaryWalletStreamUseCase = getPrimaryWalletStreamUseCase,
       _budgetRepository = budgetRepository,
       super(BudgetInitial());

  final GetPrimaryWalletStreamUseCase _getPrimaryWalletStreamUseCase;
  final BudgetRepository _budgetRepository;

  StreamSubscription<Either<dynamic, WalletEntity?>>? _walletSub;
  StreamSubscription<List<CategoryEntity>>? _categoriesSub;
  StreamSubscription<List<TransactionEntity>>? _transactionsSub;

  String? _userId;
  String? _walletId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  List<CategoryEntity> _categories = [];
  List<TransactionEntity> _transactions = [];

  void start(String userId) {
    _userId = userId;
    emit(BudgetLoading());
    _walletSub?.cancel();
    _walletSub = _getPrimaryWalletStreamUseCase(userId).listen(
      (Either<dynamic, WalletEntity?> either) {
        either.fold(
          (failure) {
            final msg = failure is Failure
                ? failure.message
                : failure.toString();
            emit(BudgetFailure(msg));
          },
          (wallet) {
            if (wallet == null) {
              _cancelCategoryAndTx();
              emit(BudgetNoWallet());
              return;
            }
            final sameWallet = _walletId == wallet.id;
            _walletId = wallet.id;
            if (!sameWallet) {
              _listenCategories(wallet.id);
            }
            _listenTransactions();
          },
        );
      },
      onError: (Object e, StackTrace st) {
        emit(BudgetFailure(e.toString()));
      },
    );
  }

  void _listenCategories(String walletId) {
    _categoriesSub?.cancel();
    _categoriesSub = _budgetRepository
        .watchBudgetCategories(walletId, month: _month.month, year: _month.year)
        .listen(
          (list) {
            _categories = list;
            _emitLoaded();
          },
          onError: (Object e, _) {
            emit(BudgetFailure(e.toString()));
          },
        );
  }

  void _listenTransactions() {
    final uid = _userId;
    if (uid == null) return;

    _transactionsSub?.cancel();
    _transactionsSub = _budgetRepository
        .watchTransactionsForMonth(
          userId: uid,
          year: _month.year,
          month: _month.month,
        )
        .listen(
          (list) {
            _transactions = list;
            _emitLoaded();
          },
          onError: (Object e, _) {
            emit(BudgetFailure(e.toString()));
          },
        );
  }

  void _emitLoaded() {
    final walletId = _walletId;
    if (walletId == null) return;

    final spentByCategory = <String, double>{};
    for (final t in _transactions) {
      if (t.type == 'Expense') {
        spentByCategory[t.categoryId] =
            (spentByCategory[t.categoryId] ?? 0) + t.amount;
      }
    }

    final outCategories = _categories
        .where((c) => c.type == CategoryType.outType)
        .toList();

    final items = outCategories
        .map(
          (c) => BudgetLineItem(
            category: c,
            spentThisMonth: spentByCategory[c.id] ?? 0,
          ),
        )
        .toList();

    final prev = state;
    final err = prev is BudgetLoaded ? prev.errorMessage : null;

    emit(
      BudgetLoaded(
        month: _month,
        items: items,
        walletId: walletId,
        errorMessage: err,
      ),
    );
  }

  void changeMonth(int monthDelta) {
    _month = DateTime(_month.year, _month.month + monthDelta);
    _transactions = [];
    _emitLoaded();
    if (_userId != null) {
      _listenTransactions();
    }
    if (_walletId != null) {
      _listenCategories(_walletId!);
    }
  }

  Future<bool> upsertCategory({
    required String walletId,
    required String id,
    required String name,
    required double budgetLimit,
    required CategoryType type,
    int? iconCodePoint,
    int? accentArgb,
  }) async {
    try {
      await _budgetRepository.upsertBudgetCategory(
        CategoryEntity(
          id: id,
          walletId: walletId,
          name: name,
          budgetLimit: budgetLimit,
          currentSpent: 0,
          type: type,
          iconCodePoint: iconCodePoint,
          accentArgb: accentArgb,
        ),
      );
      _clearSheetError();
      return true;
    } catch (e) {
      _setSheetError(e.toString());
      return false;
    }
  }

  Future<bool> deleteCategory(String walletId, String categoryId) async {
    try {
      await _budgetRepository.deleteBudgetCategory(walletId, categoryId);
      _clearSheetError();
      return true;
    } catch (e) {
      _setSheetError(e.toString());
      return false;
    }
  }

  void _setSheetError(String message) {
    final s = state;
    if (s is BudgetLoaded) {
      emit(
        BudgetLoaded(
          month: s.month,
          items: s.items,
          walletId: s.walletId,
          errorMessage: message,
        ),
      );
    }
  }

  void _clearSheetError() {
    final s = state;
    if (s is BudgetLoaded && s.errorMessage != null) {
      emit(BudgetLoaded(month: s.month, items: s.items, walletId: s.walletId));
    }
  }

  void dismissError() => _clearSheetError();

  void _cancelCategoryAndTx() {
    _categoriesSub?.cancel();
    _categoriesSub = null;
    _transactionsSub?.cancel();
    _transactionsSub = null;
    _categories = [];
    _transactions = [];
  }

  @override
  Future<void> close() {
    _walletSub?.cancel();
    _cancelCategoryAndTx();
    return super.close();
  }
}
