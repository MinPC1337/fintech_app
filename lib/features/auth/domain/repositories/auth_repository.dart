import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String fullName,
  });

  Future<Either<Failure, User>> updateProfile({
    required String uid,
    required String fullName,
    required String avatarUrl,
    required String fcmToken,
  });

  Future<Either<Failure, void>> resetPassword({required String email});

  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}
