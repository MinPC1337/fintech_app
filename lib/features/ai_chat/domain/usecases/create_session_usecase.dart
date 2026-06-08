import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_session.dart';
import '../repositories/chat_repository.dart';

class CreateSessionUseCase {
  final ChatRepository repository;

  CreateSessionUseCase(this.repository);

  Future<Either<Failure, ChatSession>> call(String userId, String title) {
    return repository.createSession(userId, title);
  }
}
