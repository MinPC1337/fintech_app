import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/push_api_client.dart';
import '../../../../core/utils/push_debug.dart';
import '../repositories/group_wallet_repository.dart';

class RemindDebtUseCase {
  final GroupWalletRepository repository;
  final PushApiClient pushApiClient;

  RemindDebtUseCase(this.repository, this.pushApiClient);

  Future<Either<Failure, void>> call(String debtId, String lenderId) async {
    PushDebug.log('Nhắc nợ start', 'debtId=$debtId lenderId=$lenderId');
    try {
      final result = await repository.remindDebt(debtId, lenderId);
      PushDebug.ok(
        'Firestore notification',
        'id=${result.notificationId} borrower=${result.borrowerId}',
      );

      try {
        await pushApiClient.sendPush(
          userId: result.borrowerId,
          title: result.title,
          body: result.body,
          type: 'debt_reminder',
          debtId: result.debtId,
          walletId: result.walletId,
          notificationId: result.notificationId,
        );
        PushDebug.ok('Nhắc nợ hoàn tất', 'inbox + đã gọi Worker');
      } catch (e, st) {
        PushDebug.warn(
          'Push thất bại (inbox vẫn có)',
          '$e',
        );
        PushDebug.log('Push stack', st.toString().split('\n').take(3).join(' | '));
      }
      return const Right(null);
    } catch (e) {
      PushDebug.fail('Nhắc nợ', '$e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
