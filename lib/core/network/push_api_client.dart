import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/push_config.dart';
import '../utils/push_debug.dart';

class PushApiClient {
  PushApiClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<void> sendPush({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? debtId,
    String? walletId,
    String? notificationId,
  }) async {
    PushDebug.log(
      'Worker sendPush start',
      'toUserId=$userId type=$type debtId=$debtId workerConfigured=${PushConfig.isConfigured}',
    );

    if (!PushConfig.isConfigured) {
      PushDebug.warn(
        'Worker skipped',
        'Thiếu PUSH_WORKER_URL. Chạy: flutter run --dart-define=PUSH_WORKER_URL=https://....workers.dev',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      PushDebug.fail('Worker sendPush', 'Chưa đăng nhập');
      throw Exception('Chưa đăng nhập');
    }

    final idToken = await user.getIdToken();
    final url = '${PushConfig.workerUrl.replaceAll(RegExp(r'/$'), '')}/send';
    PushDebug.log('Worker POST', url);

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: {
          'userId': userId,
          'title': title,
          'body': body,
          'type': type,
          'debtId': ?debtId,
          'walletId': ?walletId,
          'notificationId': ?notificationId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      final sent = data?['sent'] ?? 0;
      final failed = data?['failed'] ?? 0;
      final skipped = data?['skipped'] ?? false;
      final reason = data?['reason'] ?? '';
      PushDebug.ok(
        'Worker sendPush',
        'status=${response.statusCode} sent=$sent failed=$failed skipped=$skipped reason=$reason',
      );
      if (sent == 0 && skipped == true) {
        PushDebug.warn(
          'Worker sendPush',
          'Borrower không có FCM token trên thiết bị',
        );
      }
      if (failed > 0) {
        final failErrors = data?['failErrors'] as List<dynamic>?;
        PushDebug.warn(
          'Worker sendPush',
          'FCM gửi thất bại $failed/${sent + failed} tokens. Chi tiết lỗi: $failErrors',
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      PushDebug.fail(
        'Worker sendPush',
        'HTTP $status ${e.message} response=$body',
      );
      rethrow;
    }
  }
}
