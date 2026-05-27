import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(email, password);
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure('An unexpected error occurred during login.'),
      );
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final user = await remoteDataSource.register(email, password, fullName);
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure('An unexpected error occurred during registration.'),
      );
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    required String uid,
    required String fullName,
    required String avatarUrl,
    required String fcmToken,
  }) async {
    try {
      final user = await remoteDataSource.updateProfile(
        uid,
        fullName,
        avatarUrl,
        fcmToken,
      );
      return Right(user);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure('An unexpected error occurred during profile update.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure('An unexpected error occurred during password reset.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.changePassword(oldPassword, newPassword);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (e) {
      return const Left(
        ServerFailure('Đã xảy ra lỗi không xác định khi đổi mật khẩu.'),
      );
    }
  }
}
