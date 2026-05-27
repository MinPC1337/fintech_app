import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.updateProfileUseCase,
    required this.resetPasswordUseCase,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginParams(email: email, password: password),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> register(String email, String password, String fullName) async {
    emit(AuthLoading());
    final result = await registerUseCase(
      RegisterParams(email: email, password: password, fullName: fullName),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthVerificationRequired(user: user)),
    );
  }

  Future<void> updateProfile(
    String uid,
    String fullName,
    String avatarUrl,
    String fcmToken,
  ) async {
    emit(AuthLoading());
    final result = await updateProfileUseCase(
      UpdateProfileParams(
        uid: uid,
        fullName: fullName,
        avatarUrl: avatarUrl,
        fcmToken: fcmToken,
      ),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthSuccess(user: user)),
    );
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    final result = await resetPasswordUseCase(
      ResetPasswordParams(email: email),
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthPasswordResetSent()),
    );
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final currentState = state;
    if (currentState is! AuthSuccess) return;
    final user = currentState.user;

    emit(AuthLoading());
    final result = await loginUseCase.repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(AuthPasswordChanged(user: user)),
    );
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      await FirebaseAuth.instance.signOut();
      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(message: 'Đăng xuất thất bại: ${e.toString()}'));
    }
  }
}
