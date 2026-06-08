import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Build chuỗi context thực tế của user để inject vào Gemini session.
/// Bao gồm: số dư ví, giao dịch gần đây, tên người dùng.
class UserContextBuilder {
  final FirebaseFirestore firestore;

  UserContextBuilder({required this.firestore});

  final _currencyFmt = NumberFormat('#,###', 'vi_VN');

  /// Trả về đoạn text context để prepend vào system message của session.
  /// Chỉ gọi một lần khi bắt đầu session (history rỗng).
  Future<String> buildContext(String userId) async {
    try {
      final results = await Future.wait([
        _getWalletInfo(userId),
        _getRecentTransactions(userId),
        _getUserName(userId),
      ]);

      final walletInfo = results[0];
      final txInfo = results[1];
      final userName = results[2];

      return '''
--- THÔNG TIN THỰC TẾ CỦA NGƯỜI DÙNG (cập nhật lúc ${DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now())}) ---
Tên người dùng: $userName
$walletInfo
$txInfo
--- HẾT THÔNG TIN NGƯỜI DÙNG ---
''';
    } catch (e) {
      debugPrint('[UserContextBuilder] Error building context: $e');
      return ''; // Nếu lỗi, không inject context (AI vẫn hoạt động bình thường)
    }
  }

  Future<String> _getWalletInfo(String userId) async {
    try {
      final query = await firestore
          .collection('wallets')
          .where('ownerId', isEqualTo: userId)
          .where('isPersonal', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return 'Số dư ví: Chưa có ví cá nhân';

      final data = query.docs.first.data();
      final balance = (data['balance'] ?? 0).toDouble();
      return 'Số dư ví hiện tại: ${_currencyFmt.format(balance)} VNĐ';
    } catch (e) {
      return 'Số dư ví: Không thể truy cập';
    }
  }

  Future<String> _getRecentTransactions(String userId) async {
    try {
      final query = await firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (query.docs.isEmpty) return 'Giao dịch gần đây: Chưa có giao dịch nào.';

      final buffer = StringBuffer('5 giao dịch gần đây:\n');
      for (final doc in query.docs) {
        final d = doc.data();
        final type = d['type'] ?? '';
        final amount = (d['amount'] ?? 0).toDouble();
        final note = d['note'] ?? '';
        final ts = d['timestamp'];
        String dateStr = '';
        if (ts is Timestamp) {
          dateStr = DateFormat('dd/MM HH:mm').format(ts.toDate());
        }

        final typeLabel = type == 'Income' ? '↑ Nhận' : '↓ Chi';
        buffer.writeln('  • $typeLabel ${_currencyFmt.format(amount)} VNĐ — $note ($dateStr)');
      }
      return buffer.toString().trimRight();
    } catch (e) {
      return 'Giao dịch gần đây: Không thể truy cập';
    }
  }

  Future<String> _getUserName(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 'Người dùng';
      return doc.data()?['fullName'] ?? 'Người dùng';
    } catch (e) {
      return 'Người dùng';
    }
  }
}
