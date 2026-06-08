import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';

/// Contract cho Chat Repository.
abstract class ChatRepository {
  /// Gửi tin nhắn đến AI, nhận phản hồi (có thể chứa action).
  Future<Either<Failure, ChatMessage>> sendMessage(
    String message,
    List<ChatMessage> history,
    String userId,
  );

  /// Stream lịch sử chat của user từ Firestore.
  Stream<List<ChatMessage>> watchChatHistory(String userId);

  /// Xóa toàn bộ lịch sử chat.
  Future<Either<Failure, void>> clearHistory(String userId);
}
