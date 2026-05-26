import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/group_wallet_repository.dart';

class InviteMemberUseCase {
  final GroupWalletRepository repository;

  InviteMemberUseCase(this.repository);

  Future<Either<Failure, void>> call(String walletId, String senderId, String receiverEmail) async {
    if (receiverEmail.trim().isEmpty) {
      return const Left(ValidationFailure('Email không được để trống'));
    }
    try {
      await repository.inviteMember(walletId, senderId, receiverEmail.trim());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
