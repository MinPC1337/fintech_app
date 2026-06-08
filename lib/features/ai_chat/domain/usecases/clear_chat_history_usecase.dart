import '../repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

/// Xóa toàn bộ lịch sử chat.
class ClearChatHistoryUseCase {
  final ChatRepository repository;

  ClearChatHistoryUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId) {
    return repository.clearHistory(userId);
  }
}
