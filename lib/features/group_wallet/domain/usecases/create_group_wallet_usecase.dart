import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../main/domain/entities/wallet_entity.dart';
import '../repositories/group_wallet_repository.dart';

class CreateGroupWalletUseCase {
  final GroupWalletRepository repository;

  CreateGroupWalletUseCase(this.repository);

  Future<Either<Failure, WalletEntity>> call(String name, String ownerId, int? accentArgb, String? imageUrl, String? emoji) async {
    if (name.trim().isEmpty) {
      return const Left(ValidationFailure('Tên ví nhóm không được để trống'));
    }
    try {
      final wallet = await repository.createGroupWallet(name.trim(), ownerId, accentArgb, imageUrl, emoji);
      return Right(wallet);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
