import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Khởi tạo và xin quyền thông báo
  static Future<void> initialize() async {
    // 1. Yêu cầu quyền thông báo (iOS & Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Xử lý khi app đang mở (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 [FCM_RECEIVE] Foreground Message:');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');
    });

    // 3. Lắng nghe khi token được làm mới bởi Firebase
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
  }

  /// Lấy token hiện tại và lưu vào Firestore cho User hiện tại
  static Future<void> updateToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Lỗi lấy FCM Token: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'fcmToken': token},
      );
      debugPrint('FCM Token đã được đồng bộ lên Firestore');
    }
  }
}
