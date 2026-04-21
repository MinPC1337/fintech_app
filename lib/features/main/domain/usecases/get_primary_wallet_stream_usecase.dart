import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';
import '../entities/wallet_entity.dart';

class GetPrimaryWalletStreamUseCase {
  final WalletRepository repository;

  GetPrimaryWalletStreamUseCase(this.repository);

  Stream<Right<dynamic, WalletEntity?>> call(String userId) {
    return repository
        .getPrimaryWalletStream(userId)
        .map((wallet) {
          return Right(wallet);
        })
        .handleError((error) {
          return Left(ServerFailure(error.toString()));
        });
  }
}
