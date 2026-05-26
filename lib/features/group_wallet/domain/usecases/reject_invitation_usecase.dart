import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class RejectInvitationUseCase {
  final GroupWalletRepository repository;

  RejectInvitationUseCase(this.repository);

  Future<Either<Failure, void>> call(String invitationId) async {
    try {
      await repository.rejectInvitation(invitationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
