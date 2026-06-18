import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class ApproveCloseGroupWalletUseCase {
  final GroupWalletRepository repository;

  ApproveCloseGroupWalletUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String userId) async {
    try {
      await repository.approveCloseGroupWallet(walletId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
