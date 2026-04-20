import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String uid;
  final String email;
  final String fullName;
  final String avatarUrl;
  final String fcmToken;

  const User({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.fcmToken,
  });

  @override
  List<Object?> get props => [uid, email, fullName, avatarUrl, fcmToken];
}
