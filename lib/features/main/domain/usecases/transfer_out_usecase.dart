import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/wallet_repository.dart';

class TransferOutUseCase {
  final WalletRepository repository;

  TransferOutUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String senderUid,
    double amount,
    String targetPhone,
    String categoryId, {
    String? fromWalletId,
  }) async {
    try {
      if (amount <= 0) {
        return Left(ValidationFailure('Số tiền chuyển phải lớn hơn 0'));
      }
      if (targetPhone.isEmpty || targetPhone.length < 10) {
        return Left(ValidationFailure('Số điện thoại không hợp lệ'));
      }
      
      await repository.transferOut(
        senderUid,
        amount,
        targetPhone,
        categoryId,
        fromWalletId: fromWalletId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
