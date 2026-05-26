import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class CloseGroupWalletUseCase {
  final GroupWalletRepository repository;

  CloseGroupWalletUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String requesterId) async {
    try {
      await repository.closeGroupWallet(walletId, requesterId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
