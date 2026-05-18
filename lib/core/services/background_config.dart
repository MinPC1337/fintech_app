import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 1. Khởi tạo kênh thông báo Local Notification
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'balance_alerts_channel', // ID của kênh
  'Thông báo số dư', // Tên hiển thị
  description: 'Kênh hiển thị thông báo khi có biến động số dư',
  importance: Importance.max,
);

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Cấu hình thông báo hiển thị cố định khi app chạy ngầm (Bắt buộc cho Android)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart, // Hàm chứa logic chạy ngầm
      autoStart: true, // Tự động chạy khi mở máy/mở app
      isForegroundMode: true, // Chạy dưới dạng Foreground Service (bền bỉ nhất)
      notificationChannelId: 'balance_alerts_channel',
      initialNotificationTitle: 'Smart Finance đang hoạt động',
      initialNotificationContent: 'Đang bảo vệ tài khoản của bạn...',
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  return true;
}

// 2. NƠI CHỨA LOGIC CHẠY NGẦM CHÍNH
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo Firebase trong isolate độc lập
  await Firebase.initializeApp();

  // ID người dùng bạn muốn theo dõi (Trong thực tế nên lấy từ Storage hoặc truyền vào)
  String targetUserId = "user_id_001";
  num lastBalance = 0;
  bool isFirstLoad = true;

  // Lắng nghe Firestore Real-time trực tiếp từ Background
  FirebaseFirestore.instance
      .collection('users')
      .doc(targetUserId)
      .snapshots()
      .listen((snapshot) {
        if (snapshot.exists) {
          num currentBalance = snapshot.data()?['balance'] ?? 0;

          // Logic so sánh: Nếu số dư tăng lên so với lần đọc trước
          if (!isFirstLoad && currentBalance > lastBalance) {
            num soTienNhan = currentBalance - lastBalance;

            // Hiển thị thông báo Local Notification
            flutterLocalNotificationsPlugin.show(
              id: notificationWithRandomId(),
              title: 'Biến động số dư 💰',
              body:
                  'Tài khoản vừa được cộng +${soTienNhan.toString()}đ. Số dư mới: ${currentBalance.toString()}đ.',
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  channel.id,
                  channel.name,
                  channelDescription: channel.description,
                  icon: '@mipmap/launcher_icon',
                  importance: Importance.max,
                  priority: Priority.high,
                  color: const Color(0xFF22D3EE),
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
            );
          }

          // Cập nhật số dư cũ để so sánh lần sau
          lastBalance = currentBalance;
          isFirstLoad = false;
        }
      });
}

int notificationWithRandomId() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
