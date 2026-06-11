import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/local_notification_service.dart';
import '../../data/models/notification_model.dart';
import '../entities/category_entity.dart';

class BudgetAlertService {
  final FirebaseFirestore firestore;
  final LocalNotificationService localNotificationService;

  BudgetAlertService({
    required this.firestore,
    required this.localNotificationService,
  });

  Future<void> checkAndAlert({
    required String userId,
    required CategoryEntity category,
    required double newTotalSpent,
  }) async {
    if (category.budgetLimit <= 0) return;

    final ratio = newTotalSpent / category.budgetLimit;
    int threshold = 0;
    
    if (ratio >= 1.0) {
      threshold = 100;
    } else if (ratio >= 0.75) {
      threshold = 75;
    }

    if (threshold == 0) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final monthKey = '${now.month}_${now.year}';
    final prefKey = 'budget_alert_${userId}_${category.id}_$monthKey';

    final lastThreshold = prefs.getInt(prefKey) ?? 0;

    if (threshold > lastThreshold) {
      // Cập nhật lại mốc để không thông báo trùng
      await prefs.setInt(prefKey, threshold);

      final title = threshold == 100 
          ? 'Vượt ngân sách ${category.name}!' 
          : 'Sắp vượt ngân sách ${category.name}';
      
      final body = threshold == 100
          ? 'Bạn đã chi tiêu vượt quá 100% ngân sách tháng này.'
          : 'Bạn đã sử dụng ${ (ratio * 100).toInt() }% ngân sách tháng này. Cẩn thận chi tiêu nhé!';

      // 1. Hiển thị Local Notification
      await localNotificationService.showNotification(
        id: category.id.hashCode,
        title: title,
        body: body,
      );

      // 2. Lưu vào Firestore để hiển thị trong Tab Cảnh báo
      final docRef = firestore.collection('notifications').doc();
      final notification = NotificationModel(
        id: docRef.id,
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: 'budget_alert',
      );

      await docRef.set({
        ...notification.toJson(),
        'userId': userId,
      });
    }
  }
}
