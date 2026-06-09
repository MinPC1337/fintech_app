import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Xử lý việc thực thi các function call mà Gemini AI yêu cầu.
///
/// Khi Gemini quyết định cần lấy dữ liệu thực tế, nó sẽ trả về một
/// [FunctionCall] thay vì text. [AiFunctionHandler] nhận function name +
/// arguments, thực hiện Firestore query tương ứng, và trả kết quả dạng
/// string để gửi ngược lại cho Gemini.
class AiFunctionHandler {
  final FirebaseFirestore firestore;

  AiFunctionHandler({required this.firestore});

  final _currencyFmt = NumberFormat('#,###', 'vi_VN');

  // ────────────────────────────────────────────────────
  // Dispatcher chính
  // ────────────────────────────────────────────────────

  /// Nhận [functionName] và [args] từ Gemini, gọi hàm tương ứng.
  /// Trả về kết quả dạng string (để Gemini đọc và sinh câu trả lời cho user).
  Future<String> execute(
    String functionName,
    Map<String, Object?> args,
    String userId,
  ) async {
    debugPrint('[AiFunctionHandler] Executing: $functionName with args: $args');
    try {
      switch (functionName) {
        case 'getWalletBalance':
          return await _getWalletBalance(userId);
        case 'getRecentTransactions':
          final limit = (args['limit'] as num?)?.toInt() ?? 5;
          final type = args['type'] as String?;
          return await _getRecentTransactions(userId, limit: limit, type: type);
        case 'getBudgetStatus':
          return await _getBudgetStatus(userId);
        case 'getGroupWallets':
          return await _getGroupWallets(userId);
        case 'getPendingDebts':
          return await _getPendingDebts(userId);
        default:
          return 'Không tìm thấy function: $functionName';
      }
    } catch (e) {
      debugPrint('[AiFunctionHandler] Error in $functionName: $e');
      return 'Không thể lấy dữ liệu lúc này. Lỗi: $e';
    }
  }

  // ────────────────────────────────────────────────────
  // Function: getWalletBalance
  // ────────────────────────────────────────────────────

  Future<String> _getWalletBalance(String userId) async {
    final query = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return 'Người dùng chưa có ví cá nhân.';
    }

    final data = query.docs.first.data();
    final balance = (data['balance'] ?? 0).toDouble();
    return 'Số dư ví cá nhân hiện tại: ${_currencyFmt.format(balance)} VNĐ';
  }

  // ────────────────────────────────────────────────────
  // Function: getRecentTransactions
  // ────────────────────────────────────────────────────

  Future<String> _getRecentTransactions(
    String userId, {
    int limit = 5,
    String? type,
  }) async {
    final clampedLimit = limit.clamp(1, 10);

    Query<Map<String, dynamic>> query = firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(clampedLimit);

    if (type != null && type.isNotEmpty) {
      query = query.where('type', isEqualTo: type);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      return 'Chưa có giao dịch nào.';
    }

    final buffer = StringBuffer(
      '$clampedLimit giao dịch gần đây'
      '${type != null ? ' (loại: $type)' : ''}:\n',
    );

    for (final doc in snapshot.docs) {
      final d = doc.data();
      final txType = d['type'] ?? '';
      final amount = (d['amount'] ?? 0).toDouble();
      final note = d['note'] ?? '';
      final ts = d['timestamp'];

      String dateStr = '';
      if (ts is Timestamp) {
        dateStr = DateFormat('dd/MM HH:mm').format(ts.toDate());
      } else if (ts is String) {
        try {
          dateStr = DateFormat(
            'dd/MM HH:mm',
          ).format(DateTime.parse(ts).toLocal());
        } catch (_) {}
      }

      final typeLabel = txType == 'Income' ? '↑ Thu' : '↓ Chi';
      buffer.writeln(
        '  • $typeLabel ${_currencyFmt.format(amount)} VNĐ — $note ($dateStr)',
      );
    }

    return buffer.toString().trimRight();
  }

  // ────────────────────────────────────────────────────
  // Function: getBudgetStatus
  // ────────────────────────────────────────────────────

  Future<String> _getBudgetStatus(String userId) async {
    final now = DateTime.now();
    final month = now.month;
    final year = now.year;

    // Bước 1: Tìm ví cá nhân để lấy walletId
    final walletQuery = await firestore
        .collection('wallets')
        .where('ownerId', isEqualTo: userId)
        .where('isPersonal', isEqualTo: true)
        .limit(1)
        .get();

    if (walletQuery.docs.isEmpty) {
      return 'Người dùng chưa có ví cá nhân, không thể xem ngân sách.';
    }

    final walletId = walletQuery.docs.first.id;

    // Bước 2: Lấy các danh mục ngân sách tháng này
    final categoriesQuery = await firestore
        .collection('wallets')
        .doc(walletId)
        .collection('categories')
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    if (categoriesQuery.docs.isEmpty) {
      return 'Tháng $month/$year chưa có ngân sách nào được thiết lập.';
    }

    final buffer = StringBuffer(
      'Ngân sách tháng $month/$year:\n',
    );

    double totalLimit = 0;
    double totalSpent = 0;

    for (final doc in categoriesQuery.docs) {
      final d = doc.data();
      final name = d['name'] ?? 'Không tên';
      final limit = (d['limit'] ?? 0).toDouble();
      final spent = (d['currentSpent'] ?? 0).toDouble();
      final remaining = limit - spent;
      final isOver = spent > limit;

      totalLimit += limit;
      totalSpent += spent;

      final status = isOver
          ? '⚠️ VƯỢT ${_currencyFmt.format(spent - limit)} VNĐ'
          : 'còn ${_currencyFmt.format(remaining)} VNĐ';

      buffer.writeln(
        '  • $name: chi ${_currencyFmt.format(spent)} / '
            'hạn mức ${_currencyFmt.format(limit)} VNĐ ($status)',
      );
    }

    buffer.writeln(
      '\nTổng: chi ${_currencyFmt.format(totalSpent)} / '
          'tổng hạn mức ${_currencyFmt.format(totalLimit)} VNĐ',
    );

    return buffer.toString().trimRight();
  }

  // ────────────────────────────────────────────────────
  // Function: getGroupWallets
  // ────────────────────────────────────────────────────

  Future<String> _getGroupWallets(String userId) async {
    final query = await firestore
        .collection('wallets')
        .where('members', arrayContains: userId)
        .where('isPersonal', isEqualTo: false)
        .get();

    // Lọc chỉ nhóm active
    final activeGroups = query.docs
        .where((doc) => doc.data()['status'] != 'closed')
        .toList();

    if (activeGroups.isEmpty) {
      return 'Người dùng hiện không tham gia ví nhóm nào.';
    }

    final buffer = StringBuffer('Danh sách ví nhóm đang tham gia:\n');

    for (final doc in activeGroups) {
      final d = doc.data();
      final name = d['name'] ?? 'Không tên';
      final balance = (d['balance'] ?? 0).toDouble();
      final ownerId = d['ownerId'] ?? '';
      final members = (d['members'] as List?)?.length ?? 0;
      final role = ownerId == userId ? 'Trưởng nhóm' : 'Thành viên';

      buffer.writeln(
        '  • "$name" — Quỹ: ${_currencyFmt.format(balance)} VNĐ | '
            '$members thành viên | Vai trò: $role',
      );
    }

    return buffer.toString().trimRight();
  }

  // ────────────────────────────────────────────────────
  // Function: getPendingDebts
  // ────────────────────────────────────────────────────

  Future<String> _getPendingDebts(String userId) async {
    // Query nợ phải trả (mình là borrower)
    final borrowerQuery = firestore
        .collection('debts')
        .where('borrowerId', isEqualTo: userId)
        .where('isSettled', isEqualTo: false)
        .get();

    // Query nợ chưa thu (mình là lender)
    final lenderQuery = firestore
        .collection('debts')
        .where('lenderId', isEqualTo: userId)
        .where('isSettled', isEqualTo: false)
        .get();

    final results = await Future.wait([borrowerQuery, lenderQuery]);
    final myDebts = results[0].docs;   // tôi nợ người khác
    final owedToMe = results[1].docs;  // người khác nợ tôi

    if (myDebts.isEmpty && owedToMe.isEmpty) {
      return 'Hiện không có khoản nợ nào chưa thanh toán.';
    }

    final buffer = StringBuffer('Tình trạng nợ hiện tại:\n');

    if (myDebts.isNotEmpty) {
      double totalOwed = 0;
      buffer.writeln('\n📤 Tôi đang nợ:');
      for (final doc in myDebts) {
        final d = doc.data();
        final amount = (d['amount'] ?? 0).toDouble();
        final lenderId = d['lenderId'] as String? ?? '';
        totalOwed += amount;

        // Lấy tên người cho vay
        final lenderName = await _getUserName(lenderId);
        buffer.writeln(
          '  • Nợ $lenderName: ${_currencyFmt.format(amount)} VNĐ',
        );
      }
      buffer.writeln(
        '  → Tổng cần trả: ${_currencyFmt.format(totalOwed)} VNĐ',
      );
    }

    if (owedToMe.isNotEmpty) {
      double totalReceivable = 0;
      buffer.writeln('\n📥 Người khác đang nợ tôi:');
      for (final doc in owedToMe) {
        final d = doc.data();
        final amount = (d['amount'] ?? 0).toDouble();
        final borrowerId = d['borrowerId'] as String? ?? '';
        totalReceivable += amount;

        // Lấy tên người nợ
        final borrowerName = await _getUserName(borrowerId);
        buffer.writeln(
          '  • $borrowerName nợ: ${_currencyFmt.format(amount)} VNĐ',
        );
      }
      buffer.writeln(
        '  → Tổng sẽ thu: ${_currencyFmt.format(totalReceivable)} VNĐ',
      );
    }

    return buffer.toString().trimRight();
  }

  // ────────────────────────────────────────────────────
  // Helper
  // ────────────────────────────────────────────────────

  Future<String> _getUserName(String uid) async {
    if (uid.isEmpty) return 'Người dùng';
    try {
      final doc = await firestore.collection('users').doc(uid).get();
      if (!doc.exists) return 'Người dùng';
      return doc.data()?['fullName'] as String? ?? 'Người dùng';
    } catch (_) {
      return 'Người dùng';
    }
  }
}
