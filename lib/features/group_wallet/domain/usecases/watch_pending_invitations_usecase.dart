import '../../../main/domain/entities/invitation_entity.dart';
import '../repositories/group_wallet_repository.dart';

class WatchPendingInvitationsUseCase {
  final GroupWalletRepository repository;

  WatchPendingInvitationsUseCase(this.repository);

  Stream<List<InvitationEntity>> call(String userId) {
    return repository.watchPendingInvitations(userId);
  }
}
