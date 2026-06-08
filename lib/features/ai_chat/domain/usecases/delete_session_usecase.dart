import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/chat_repository.dart';

class DeleteSessionUseCase {
  final ChatRepository repository;

  DeleteSessionUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId, String sessionId) {
    return repository.deleteSession(userId, sessionId);
  }
}
