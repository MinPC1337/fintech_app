import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/repositories/wallet_repository.dart';

class TransferToUserUseCase {
  final WalletRepository repository;

  TransferToUserUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String senderUid,
    String receiverUid,
    double amount,
  ) async {
    try {
      await repository.transferToUser(senderUid, receiverUid, amount);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
