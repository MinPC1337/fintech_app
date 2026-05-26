import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class WithdrawFromGroupUseCase {
  final GroupWalletRepository repository;

  WithdrawFromGroupUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String requesterId, double amount, String note) async {
    if (amount <= 0) {
      return const Left(ValidationFailure('Số tiền rút phải lớn hơn 0'));
    }
    try {
      await repository.withdrawFromGroup(walletId, requesterId, amount, note);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
