import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

class WatchSessionsUseCase {
  final ChatRepository repository;

  WatchSessionsUseCase(this.repository);

  Stream<List<ChatSession>> call(String userId) {
    return repository.watchSessions(userId);
  }
}
