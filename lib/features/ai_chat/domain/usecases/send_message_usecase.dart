import '../entities/chat_message.dart';
import '../repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

/// Gửi tin nhắn đến AI và nhận phản hồi.
class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, ChatMessage>> call({
    required String message,
    required List<ChatMessage> history,
    required String userId,
    required String sessionId,
  }) {
    return repository.sendMessage(message, history, userId, sessionId);
  }
}
