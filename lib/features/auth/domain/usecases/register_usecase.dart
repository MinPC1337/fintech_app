import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<User, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    // Validate email format and password length as per Grapuco rules
    if (params.password.length < 8) {
      return const Left(ValidationFailure("Mật khẩu tối thiểu 8 ký tự"));
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(params.email)) {
      return const Left(ValidationFailure("Email phải đúng định dạng"));
    }

    return await repository.register(
      email: params.email, 
      password: params.password, 
      fullName: params.fullName,
    );
  }
}

class RegisterParams extends Equatable {
  final String email;
  final String password;
  final String fullName;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, password, fullName];
}
