import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class RemoveMemberUseCase {
  final GroupWalletRepository repository;

  RemoveMemberUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String memberId, String requesterId) async {
    try {
      await repository.removeMember(walletId, memberId, requesterId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
