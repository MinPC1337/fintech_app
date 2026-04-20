import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String fullName);
  Future<UserModel> updateProfile(
    String uid,
    String fullName,
    String avatarUrl,
    String fcmToken,
  );
  Future<void> resetPassword(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final firebase.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!credential.user!.emailVerified) {
        // Re-send verification email for convenience
        await credential.user!.sendEmailVerification();
        await firebaseAuth.signOut(); // Sign out the unverified user
        throw const ValidationFailure(
          'Vui lòng xác thực email. Một email mới đã được gửi đến hộp thư của bạn.',
        );
      }

      final uid = credential.user!.uid;
      final doc = await firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      } else {
        throw const ServerFailure('User data not found in database');
      }
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        throw const ValidationFailure('Email hoặc mật khẩu không chính xác');
      }
      throw ServerFailure(e.message ?? 'Unknown Firebase Error');
    } catch (e) {
      throw const ServerFailure('Login Failed');
    }
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send verification email
      await credential.user?.sendEmailVerification();

      final userModel = UserModel(
        uid: credential.user!.uid,
        email: email,
        fullName: fullName,
        avatarUrl: '',
        fcmToken: '',
      );

      await firestore
          .collection('users')
          .doc(userModel.uid)
          .set(userModel.toJson());

      // Sign out the user immediately after registration.
      // This forces them to go through the login flow, which checks for email verification.
      await firebaseAuth.signOut();

      return userModel;
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const ValidationFailure('Email đã được đăng ký');
      }
      throw ServerFailure(e.message ?? 'Unknown Firebase Error');
    } catch (e) {
      throw const ServerFailure('Registration Failed');
    }
  }

  @override
  Future<UserModel> updateProfile(
    String uid,
    String fullName,
    String avatarUrl,
    String fcmToken,
  ) async {
    try {
      await firestore.collection('users').doc(uid).update({
        'fullName': fullName,
        'avatarUrl': avatarUrl,
        'fcmToken': fcmToken,
      });

      final doc = await firestore.collection('users').doc(uid).get();
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw const ServerFailure('Update profile failed');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw const ValidationFailure('Không tìm thấy tài khoản với email này');
      }
      throw ServerFailure(e.message ?? 'Lỗi Firebase không xác định');
    } catch (e) {
      throw const ServerFailure('Gửi email khôi phục thất bại');
    }
  }
}
