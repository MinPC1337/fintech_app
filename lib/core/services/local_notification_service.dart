import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Cấu hình cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(
          '@mipmap/launcher_icon',
        ); // Đảm bảo bạn có icon này trong res/drawable

    // Cấu hình cho iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Xử lý khi người dùng nhấn vào thông báo
        print("Notification clicked with payload: ${details.payload}");
      },
    );

    // Yêu cầu quyền trên Android 13+
    if (Platform.isAndroid) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Cấu hình Channel cho Android (Bắt buộc)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'fintech_app_channel', // ID của channel
          'Fintech Notifications', // Tên hiển thị trong cài đặt máy
          channelDescription: 'Thông báo về giao dịch và biến động số dư',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          // Bạn có thể thêm icon hoặc màu sắc ở đây để đồng bộ với theme Neon
          color: Color(0xFF22D3EE),
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
