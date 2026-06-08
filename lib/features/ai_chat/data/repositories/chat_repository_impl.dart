import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/gemini_remote_data_source.dart';
import '../datasources/chat_history_data_source.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final GeminiRemoteDataSource geminiDataSource;
  final ChatHistoryDataSource chatHistoryDataSource;

  ChatRepositoryImpl({
    required this.geminiDataSource,
    required this.chatHistoryDataSource,
  });

  @override
  Future<Either<Failure, ChatMessage>> sendMessage(
    String message,
    List<ChatMessage> history,
    String userId,
  ) async {
    try {
      // 1. Lưu tin nhắn của user vào history
      final userMessage = ChatMessageModel(
        id: '${DateTime.now().millisecondsSinceEpoch}_u',
        content: message,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      await chatHistoryDataSource.saveMessage(userId, userMessage);

      // 2. Gửi request đến Gemini
      final assistantMessage = await geminiDataSource.sendMessage(message, history);

      // 3. Lưu phản hồi của AI vào history
      final assistantMessageModel = ChatMessageModel.fromEntity(assistantMessage);
      await chatHistoryDataSource.saveMessage(userId, assistantMessageModel);

      return Right(assistantMessage);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<ChatMessage>> watchChatHistory(String userId) {
    return chatHistoryDataSource.watchChatHistory(userId);
  }

  @override
  Future<Either<Failure, void>> clearHistory(String userId) async {
    try {
      await chatHistoryDataSource.clearHistory(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
