import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class SettleDebtUseCase {
  final GroupWalletRepository repository;

  SettleDebtUseCase(this.repository);

  Future<Either<Failure, void>> call(String debtId, String borrowerId) async {
    try {
      await repository.settleDebt(debtId, borrowerId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
