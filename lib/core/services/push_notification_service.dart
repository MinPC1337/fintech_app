import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/push_config.dart';
import '../navigation/app_navigator.dart';
import '../utils/push_debug.dart';
import 'local_notification_service.dart';
import '../../features/group_wallet/presentation/pages/group_wallet_detail_page.dart';
import '../../features/main/presentation/pages/notifications_page.dart';

const _deviceIdKey = 'fcm_device_id';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  PushDebug.log(
    'FCM background message',
    'title=${message.notification?.title} data=${message.data}',
  );

  final title = message.notification?.title ?? message.data['title'] as String?;
  final body = message.notification?.body ?? message.data['body'] as String?;

  if (title != null && title.isNotEmpty) {
    final localNotif = LocalNotificationService();
    await localNotif.init();
    await localNotif.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body ?? '',
      payload: message.data['walletId'] as String?,
    );
  }
}

class PushNotificationService {
  PushNotificationService({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required LocalNotificationService localNotificationService,
  })  : _messaging = messaging,
        _firestore = firestore,
        _localNotificationService = localNotificationService;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final LocalNotificationService _localNotificationService;

  bool _initialized = false;
  String? _currentUid;

  Future<void> init() async {
    if (_initialized) return;

    PushDebug.log('Init start', 'workerUrl=${PushConfig.workerUrl.isEmpty ? "(chưa cấu hình)" : PushConfig.workerUrl}');

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    NotificationSettings settings;
    if (Platform.isIOS) {
      settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      settings = await _messaging.requestPermission();
    }
    PushDebug.log(
      'FCM permission',
      'authorized=${settings.authorizationStatus}',
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      PushDebug.log('FCM opened from tray', 'data=${message.data}');
      _handleMessageNavigation(message);
    });

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      PushDebug.log('FCM cold start from notification', 'data=${initial.data}');
      _handleMessageNavigation(initial);
    }

    _messaging.onTokenRefresh.listen((token) async {
      PushDebug.log('FCM token refresh', PushDebug.maskToken(token));
      final uid = _currentUid;
      if (uid != null) {
        await _saveToken(uid, token);
      }
    });

    _initialized = true;
    PushDebug.ok('Init done');
  }

  Future<void> syncTokenForUser(String uid) async {
    PushDebug.log('syncTokenForUser', 'uid=$uid');
    _currentUid = uid;
    try {
      // Xoá token cũ để tránh rò rỉ thông báo khi chuyển tài khoản trên cùng thiết bị
      try {
        await _messaging.deleteToken();
      } catch (e) {
        PushDebug.warn('syncTokenForUser', 'deleteToken lỗi nhẹ: $e');
      }

      final token = await _messaging.getToken();
      if (token == null) {
        PushDebug.warn('syncTokenForUser', 'getToken() returned null');
        return;
      }
      PushDebug.log('FCM getToken', PushDebug.maskToken(token));
      await _saveToken(uid, token);
      PushDebug.ok('syncTokenForUser', 'đã ghi Firestore users/$uid.fcmTokens');
    } catch (e, st) {
      PushDebug.fail('syncTokenForUser', '$e\n$st');
    }
  }

  Future<void> clearTokenForUser(String uid) async {
    PushDebug.log('clearTokenForUser', 'uid=$uid');
    try {
      final deviceId = await _getOrCreateDeviceId();
      await _firestore.collection('users').doc(uid).update({
        'fcmTokens.$deviceId': FieldValue.delete(),
      });
      _currentUid = null;
      await _messaging.deleteToken();
      PushDebug.ok('clearTokenForUser');
    } catch (e, st) {
      PushDebug.fail('clearTokenForUser', '$e\n$st');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    PushDebug.log(
      'FCM foreground',
      'title=${message.notification?.title} data=${message.data}',
    );
    final title = message.notification?.title ?? message.data['title'] as String? ?? 'Thông báo';
    final body = message.notification?.body ?? message.data['body'] as String? ?? '';
    await _localNotificationService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: message.data['walletId'],
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];
    final walletId = data['walletId'];
    final userId = FirebaseAuth.instance.currentUser?.uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = rootNavigatorKey.currentState;
      if (nav == null) {
        PushDebug.warn('Deep link', 'navigator chưa sẵn sàng');
        return;
      }

      if (type == 'debt_reminder' &&
          walletId != null &&
          walletId.isNotEmpty) {
        PushDebug.log('Deep link', 'GroupWalletDetail walletId=$walletId');
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => GroupWalletDetailPage(walletId: walletId),
          ),
        );
        return;
      }

      if (userId != null) {
        PushDebug.log('Deep link', 'NotificationsPage userId=$userId');
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => NotificationsPage(userId: userId),
          ),
        );
      }
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    final deviceId = await _getOrCreateDeviceId();
    PushDebug.log('Firestore save token', 'deviceId=$deviceId');
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': {deviceId: token},
    }, SetOptions(merge: true));
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceIdKey);
    if (id == null || id.isEmpty) {
      id = DateTime.now().microsecondsSinceEpoch.toString();
      await prefs.setString(_deviceIdKey, id);
      PushDebug.log('New deviceId', id);
    }
    return id;
  }
}
