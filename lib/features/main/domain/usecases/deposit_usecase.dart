import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class DepositUseCase {
  final WalletRepository repository;

  DepositUseCase(this.repository);

  Future<Either<Failure, void>> call(String receiverUid, double amount) async {
    if (amount <= 0) {
      return Left(ServerFailure('Số tiền nạp phải lớn hơn 0'));
    }

    try {
      await repository.depositToWallet(receiverUid, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
