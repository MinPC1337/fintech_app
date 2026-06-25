import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/rag_remote_data_source.dart';
import '../datasources/chat_history_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final RagRemoteDataSource ragDataSource;
  final ChatHistoryDataSource chatHistoryDataSource;

  ChatRepositoryImpl({
    required this.ragDataSource,
    required this.chatHistoryDataSource,
  });

  @override
  Stream<List<ChatSession>> watchSessions(String userId) {
    return chatHistoryDataSource.watchSessions(userId);
  }

  @override
  Future<Either<Failure, ChatSession>> createSession(
    String userId,
    String title,
  ) async {
    try {
      final session = await chatHistoryDataSource.createSession(userId, title);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(
    String userId,
    String sessionId,
  ) async {
    try {
      await chatHistoryDataSource.deleteSession(userId, sessionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    String message,
    List<ChatMessage> history,
    String userId,
    String sessionId,
  ) async {
    try {
      if (history.isEmpty) {
        final title =
            message.length > 30 ? '${message.substring(0, 30)}...' : message;
        await chatHistoryDataSource.updateSessionTitle(
          userId,
          sessionId,
          title,
        );
      }

      final userMessage = ChatMessageModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_u',
        content: message,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      await chatHistoryDataSource.saveMessage(userId, sessionId, userMessage);

      // Gửi request đến FastAPI backend
      final assistantMessage = await ragDataSource.sendMessage(
        message: message,
        sessionId: sessionId,
        history: history,
        userId: userId,
      );

      final assistantMessageModel = ChatMessageModel.fromEntity(
        assistantMessage,
      );
      await chatHistoryDataSource.saveMessage(
        userId,
        sessionId,
        assistantMessageModel,
      );

      return Right(assistantMessage);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<ChatMessage>> watchChatHistory(
    String userId,
    String sessionId,
  ) {
    return chatHistoryDataSource.watchChatHistory(userId, sessionId);
  }

  @override
  Future<Either<Failure, void>> clearHistory(
    String userId,
    String sessionId,
  ) async {
    try {
      await chatHistoryDataSource.clearHistory(userId, sessionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
