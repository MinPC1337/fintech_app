import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase implements UseCase<User, UpdateProfileParams> {
  final AuthRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateProfileParams params) async {
    return await repository.updateProfile(
      uid: params.uid,
      fullName: params.fullName,
      avatarUrl: params.avatarUrl,
      fcmToken: params.fcmToken,
    );
  }
}

class UpdateProfileParams extends Equatable {
  final String uid;
  final String fullName;
  final String avatarUrl;
  final String fcmToken;

  const UpdateProfileParams({
    required this.uid,
    required this.fullName,
    required this.avatarUrl,
    required this.fcmToken,
  });

  @override
  List<Object?> get props => [uid, fullName, avatarUrl, fcmToken];
}
