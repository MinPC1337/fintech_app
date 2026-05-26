import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class ContributeToGroupUseCase {
  final GroupWalletRepository repository;

  ContributeToGroupUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String senderId, double amount) async {
    if (amount <= 0) {
      return const Left(ValidationFailure('Số tiền nạp phải lớn hơn 0'));
    }
    try {
      await repository.contributeToGroup(walletId, senderId, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
