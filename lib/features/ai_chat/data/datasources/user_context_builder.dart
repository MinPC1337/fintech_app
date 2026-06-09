import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Build chuỗi context thực tế của user để inject vào Gemini session.
///
/// Được gọi MỘT LẦN khi session mới bắt đầu (history rỗng).
/// Context bao gồm:
/// - Thông tin tài khoản (tên, email)
/// - Số dư ví cá nhân
/// - 5 giao dịch gần nhất
/// - Tóm tắt ngân sách tháng này
/// - Danh sách ví nhóm
/// - Tóm tắt nợ chưa trả
class UserContextBuilder {
  final FirebaseFirestore firestore;

  UserContextBuilder({required this.firestore});

  final _currencyFmt = NumberFormat('#,###', 'vi_VN');

  /// Trả về đoạn text context để prepend vào system message của session.
  Future<String> buildContext(String userId) async {
    try {
      final results = await Future.wait([
        _getUserInfo(userId),
        _getWalletInfo(userId),
        _getRecentTransactions(userId),
        _getBudgetSummary(userId),
        _getGroupWalletsSummary(userId),
        _getDebtSummary(userId),
      ]);

      final userInfo = results[0];
      final walletInfo = results[1];
      final txInfo = results[2];
      final budgetInfo = results[3];
      final groupInfo = results[4];
      final debtInfo = results[5];

      return '''
--- THÔNG TIN THỰC TẾ CỦA NGƯỜI DÙNG (cập nhật lúc ${DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now())}) ---
$userInfo
$walletInfo
$txInfo
$budgetInfo
$groupInfo
$debtInfo
--- HẾT THÔNG TIN NGƯỜI DÙNG ---

LƯU Ý: Khi user hỏi về dữ liệu mới hơn (ví dụ số dư hiện tại, giao dịch mới nhất), hãy dùng Function Calling để lấy dữ liệu cập nhật thay vì dùng context trên.
''';
    } catch (e) {
      debugPrint('[UserContextBuilder] Error building context: $e');
      return ''; // Nếu lỗi, AI vẫn hoạt động bình thường
    }
  }

  // ────────────────────────────────────────────────────
  // User info (tên + email)
  // ────────────────────────────────────────────────────

  Future<String> _getUserInfo(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (!doc.exists) return 'Tên người dùng: Người dùng';

      final data = doc.data()!;
      final name = data['fullName'] as String? ?? 'Người dùng';
      final email = data['email'] as String? ?? '';
      final accountNumber = data['accountNumber'] as String? ?? '';

      final buffer = StringBuffer('Tên người dùng: $name');
      if (email.isNotEmpty) buffer.write('\nEmail: $email');
      if (accountNumber.isNotEmpty) {
        buffer.write('\nSố tài khoản Smart Finance: $accountNumber');
      }
      return buffer.toString();
    } catch (e) {
      return 'Tên người dùng: Người dùng';
    }
  }

  // ────────────────────────────────────────────────────
  // Wallet balance
  // ────────────────────────────────────────────────────

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
      return 'Số dư ví cá nhân: ${_currencyFmt.format(balance)} VNĐ';
    } catch (e) {
      return 'Số dư ví: Không thể truy cập';
    }
  }

  // ────────────────────────────────────────────────────
  // Recent transactions (5 giao dịch gần nhất)
  // ────────────────────────────────────────────────────

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

        final typeLabel = type == 'Income' ? '↑ Thu' : '↓ Chi';
        buffer.writeln(
          '  • $typeLabel ${_currencyFmt.format(amount)} VNĐ — $note ($dateStr)',
        );
      }
      return buffer.toString().trimRight();
    } catch (e) {
      return 'Giao dịch gần đây: Không thể truy cập';
    }
  }

  // ────────────────────────────────────────────────────
  // Budget summary (tháng hiện tại)
  // ────────────────────────────────────────────────────

  Future<String> _getBudgetSummary(String userId) async {
    try {
      final now = DateTime.now();

      // Tìm ví cá nhân để lấy walletId
      final walletQuery = await firestore
          .collection('wallets')
          .where('ownerId', isEqualTo: userId)
          .where('isPersonal', isEqualTo: true)
          .limit(1)
          .get();

      if (walletQuery.docs.isEmpty) return '';

      final walletId = walletQuery.docs.first.id;

      // Lấy danh mục ngân sách tháng này
      final categoriesQuery = await firestore
          .collection('wallets')
          .doc(walletId)
          .collection('categories')
          .where('month', isEqualTo: now.month)
          .where('year', isEqualTo: now.year)
          .get();

      if (categoriesQuery.docs.isEmpty) {
        return 'Ngân sách tháng ${now.month}/${now.year}: Chưa thiết lập.';
      }

      double totalLimit = 0;
      double totalSpent = 0;
      int overBudgetCount = 0;

      final buffer = StringBuffer(
        'Ngân sách tháng ${now.month}/${now.year}:\n',
      );

      for (final doc in categoriesQuery.docs) {
        final d = doc.data();
        final name = d['name'] ?? 'Không tên';
        final limit = (d['limit'] ?? 0).toDouble();
        final spent = (d['currentSpent'] ?? 0).toDouble();
        final isOver = spent > limit;

        totalLimit += limit;
        totalSpent += spent;
        if (isOver) overBudgetCount++;

        final status = isOver
            ? '⚠️ VƯỢT ${_currencyFmt.format(spent - limit)} VNĐ'
            : 'còn ${_currencyFmt.format(limit - spent)} VNĐ';

        buffer.writeln(
          '  • $name: ${_currencyFmt.format(spent)} / ${_currencyFmt.format(limit)} VNĐ ($status)',
        );
      }

      buffer.write(
        'Tổng chi: ${_currencyFmt.format(totalSpent)} / ${_currencyFmt.format(totalLimit)} VNĐ',
      );
      if (overBudgetCount > 0) {
        buffer.write(' | $overBudgetCount danh mục vượt ngân sách!');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('[UserContextBuilder] Error getting budget: $e');
      return '';
    }
  }

  // ────────────────────────────────────────────────────
  // Group wallets summary
  // ────────────────────────────────────────────────────

  Future<String> _getGroupWalletsSummary(String userId) async {
    try {
      final query = await firestore
          .collection('wallets')
          .where('members', arrayContains: userId)
          .where('isPersonal', isEqualTo: false)
          .get();

      final activeGroups = query.docs
          .where((doc) => doc.data()['status'] != 'closed')
          .toList();

      if (activeGroups.isEmpty) return 'Ví nhóm: Không tham gia nhóm nào.';

      final buffer = StringBuffer(
        'Ví nhóm đang tham gia (${activeGroups.length} nhóm):\n',
      );

      for (final doc in activeGroups) {
        final d = doc.data();
        final name = d['name'] ?? 'Không tên';
        final balance = (d['balance'] ?? 0).toDouble();
        final isOwner = d['ownerId'] == userId;
        final memberCount = (d['members'] as List?)?.length ?? 0;

        buffer.writeln(
          '  • "$name" — ${_currencyFmt.format(balance)} VNĐ | '
              '$memberCount thành viên | ${isOwner ? "Trưởng nhóm" : "Thành viên"}',
        );
      }

      return buffer.toString().trimRight();
    } catch (e) {
      return '';
    }
  }

  // ────────────────────────────────────────────────────
  // Debt summary
  // ────────────────────────────────────────────────────

  Future<String> _getDebtSummary(String userId) async {
    try {
      final results = await Future.wait([
        firestore
            .collection('debts')
            .where('borrowerId', isEqualTo: userId)
            .where('isSettled', isEqualTo: false)
            .get(),
        firestore
            .collection('debts')
            .where('lenderId', isEqualTo: userId)
            .where('isSettled', isEqualTo: false)
            .get(),
      ]);

      final myDebts = results[0].docs;    // tôi nợ
      final owedToMe = results[1].docs;   // người khác nợ tôi

      if (myDebts.isEmpty && owedToMe.isEmpty) return '';

      final buffer = StringBuffer('Tình trạng nợ:\n');

      if (myDebts.isNotEmpty) {
        final totalOwed = myDebts.fold<double>(
          0,
          (sum, doc) => sum + (doc.data()['amount'] ?? 0).toDouble(),
        );
        buffer.writeln(
          '  • Tôi đang nợ: ${myDebts.length} khoản, '
              'tổng ${_currencyFmt.format(totalOwed)} VNĐ',
        );
      }

      if (owedToMe.isNotEmpty) {
        final totalReceivable = owedToMe.fold<double>(
          0,
          (sum, doc) => sum + (doc.data()['amount'] ?? 0).toDouble(),
        );
        buffer.writeln(
          '  • Người khác nợ tôi: ${owedToMe.length} khoản, '
              'tổng ${_currencyFmt.format(totalReceivable)} VNĐ',
        );
      }

      return buffer.toString().trimRight();
    } catch (e) {
      return '';
    }
  }
}
