import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class RejectCloseGroupWalletUseCase {
  final GroupWalletRepository repository;

  RejectCloseGroupWalletUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String userId) async {
    try {
      await repository.rejectCloseGroupWallet(walletId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
