import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';

/// Stream lịch sử chat của user.
class GetChatHistoryUseCase {
  final ChatRepository repository;

  GetChatHistoryUseCase(this.repository);

  Stream<List<ChatMessage>> call(String userId) {
    return repository.watchChatHistory(userId);
  }
}
