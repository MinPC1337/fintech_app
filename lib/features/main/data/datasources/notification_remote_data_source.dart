import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final FirebaseFirestore firestore;

  NotificationRemoteDataSource({required this.firestore});

  /// Lấy danh sách thông báo của user theo thời gian thực
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return NotificationModel.fromJson({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  /// Lấy số lượng thông báo chưa đọc theo thời gian thực
  Stream<int> getUnreadCountStream(String userId) {
    return firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    await firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Đánh dấu tất cả thông báo của một `type` cụ thể cho user là đã đọc
  Future<void> markAllAsReadForUserAndType(String userId, String type) async {
    final snapshot = await firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
