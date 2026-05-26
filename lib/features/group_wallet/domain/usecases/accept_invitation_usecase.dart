import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class AcceptInvitationUseCase {
  final GroupWalletRepository repository;

  AcceptInvitationUseCase(this.repository);

  Future<Either<Failure, void>> call(String invitationId, String userId) async {
    try {
      await repository.acceptInvitation(invitationId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
