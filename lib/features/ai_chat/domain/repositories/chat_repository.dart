import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../entities/chat_session.dart';

/// Contract cho Chat Repository.
abstract class ChatRepository {
  /// Lấy danh sách các phiên chat của user.
  Stream<List<ChatSession>> watchSessions(String userId);

  /// Tạo một phiên chat mới.
  Future<Either<Failure, ChatSession>> createSession(String userId, String title);

  /// Xóa một phiên chat.
  Future<Either<Failure, void>> deleteSession(String userId, String sessionId);

  /// Gửi tin nhắn đến AI, nhận phản hồi (có thể chứa action).
  Future<Either<Failure, ChatMessage>> sendMessage(
    String message,
    List<ChatMessage> history,
    String userId,
    String sessionId,
  );

  /// Stream lịch sử chat của user từ Firestore theo session.
  Stream<List<ChatMessage>> watchChatHistory(String userId, String sessionId);

  /// Xóa toàn bộ lịch sử của một session (có thể dùng chung với deleteSession).
  Future<Either<Failure, void>> clearHistory(String userId, String sessionId);
}
