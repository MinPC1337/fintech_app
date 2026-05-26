import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class SplitExpenseUseCase {
  final GroupWalletRepository repository;

  SplitExpenseUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String walletId,
    String payerId,
    double totalAmount,
    String note,
    List<String> participantIds,
  ) async {
    if (totalAmount <= 0) {
      return const Left(ValidationFailure('Số tiền chia phải lớn hơn 0'));
    }
    if (participantIds.length < 2) {
      return const Left(ValidationFailure('Cần ít nhất 2 người tham gia để chia tiền'));
    }
    try {
      await repository.splitExpense(walletId, payerId, totalAmount, note, participantIds);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
