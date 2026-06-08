import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_action.dart';
import 'gemini_session_manager.dart';
import 'user_context_builder.dart';

abstract class GeminiRemoteDataSource {
  /// Gửi [message] trong phiên [sessionId].
  /// [history] được dùng để restore session nếu chưa có trong cache.
  /// [userId] dùng để build user context khi bắt đầu session mới.
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    required List<ChatMessage> history,
    required String userId,
  });

  /// Xóa session khỏi cache in-memory (khi xóa session).
  void removeSession(String sessionId);

  /// Reset session trong cache (khi clear history).
  void clearSession(String sessionId);
}

class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  final GeminiSessionManager sessionManager;
  final UserContextBuilder userContextBuilder;

  GeminiRemoteDataSourceImpl({
    required this.sessionManager,
    required this.userContextBuilder,
  });

  static const String systemPrompt = '''
Bạn là trợ lý tài chính AI thông minh trong ứng dụng "Smart Finance" — ứng dụng quản lý tài chính cá nhân và nhóm dành cho người dùng Việt Nam.

═══════════════════════════════════════
TỔNG QUAN ỨNG DỤNG SMART FINANCE
═══════════════════════════════════════

Smart Finance giúp người dùng:
✦ Quản lý ví cá nhân (nạp, rút, chuyển tiền)
✦ Theo dõi ngân sách chi tiêu theo danh mục
✦ Quản lý ví nhóm (chia tiền, đòi nợ, quỹ chung)
✦ Xem lịch sử giao dịch đầy đủ
✦ Nhận thông báo giao dịch và nhắc nợ

═══════════════════════════════════════
CHI TIẾT CÁC TÍNH NĂNG
═══════════════════════════════════════

💰 VÍ CÁ NHÂN (Trang chủ - home):
• Xem số dư hiện tại của ví
• Nạp tiền: Chuyển từ MoMo vào Smart Finance (nhập số điện thoại MoMo + số tiền)
• Rút tiền: Chuyển từ Smart Finance ra MoMo (nhập số điện thoại MoMo đích + số tiền)
• Chuyển tiền nội bộ: Chuyển cho user khác trong app qua số tài khoản Smart Finance
• Nhận tiền: Chia sẻ QR code để người khác chuyển vào ví

📊 NGÂN SÁCH (Budget - budget):
• Thiết lập hạn mức chi tiêu cho từng danh mục mỗi tháng
• Danh mục chi tiêu có sẵn: Ăn uống, Di chuyển, Mua sắm, Giải trí, Sức khỏe, Khác
• Theo dõi chi tiêu thực tế vs. ngân sách đặt ra
• Biểu đồ tròn thống kê phân bổ chi tiêu theo tháng
• Khi chi tiêu vượt ngân sách → cảnh báo màu đỏ
• Thêm ngân sách mới: chọn danh mục, nhập hạn mức, chọn tháng/năm

👥 VÍ NHÓM (Group Wallet - group_wallet):
• Tạo ví nhóm: đặt tên nhóm + mục tiêu quỹ (ví dụ: "Du lịch Đà Nẵng")
• Mời thành viên: chia sẻ QR code hoặc link mời
• Chấp nhận/từ chối lời mời tham gia nhóm
• Góp tiền vào quỹ nhóm (từ ví cá nhân → ví nhóm)
• Rút tiền từ quỹ nhóm (chỉ admin)
• Chia tiền chi tiêu (Split Expense): nhập tổng chi phí → chia đều cho các thành viên → tạo danh sách nợ
• Thanh toán nợ (Settle Debt): thành viên nợ bấm "Thanh toán" → trừ từ ví cá nhân
• Nhắc nợ: gửi thông báo nhắc thành viên chưa trả nợ
• Xem lịch sử giao dịch nhóm
• Xem danh sách nợ trong nhóm
• Giải tán nhóm: chỉ admin mới có quyền (xóa toàn bộ dữ liệu nhóm)
• Xóa thành viên: admin có thể kick thành viên

🔔 THÔNG BÁO (notifications):
• Thông báo khi nhận tiền, chuyển tiền thành công
• Thông báo khi được mời vào nhóm
• Thông báo nhắc nợ từ thành viên nhóm
• Đánh dấu đã đọc tất cả thông báo

📋 LỊCH SỬ GIAO DỊCH (transaction_history):
• Xem toàn bộ giao dịch cá nhân (nạp, rút, chuyển, nhận)
• Hiển thị thời gian, số tiền, loại giao dịch, ghi chú

⚙️ CÀI ĐẶT & HỒ SƠ (settings / profile):
• Cập nhật tên hiển thị, ảnh đại diện
• Đổi mật khẩu
• Đăng xuất khỏi tài khoản

═══════════════════════════════════════
QUY TẮC TRẢ LỜI
═══════════════════════════════════════

QUAN TRỌNG: LUÔN trả về đúng một JSON hợp lệ, KHÔNG có markdown, KHÔNG có ```json.

Khi người dùng hỏi về tính năng, hướng dẫn, tư vấn tài chính → trả về:
{"action": "none", "message": "Câu trả lời đầy đủ, thân thiện, dễ hiểu của bạn"}

Khi người dùng muốn đi đến một trang cụ thể → GỢI Ý và hỏi xác nhận, trả về:
{"action": "navigate", "target": "TÊN_TRANG", "message": "Giải thích + hỏi xác nhận"}

Ví dụ:
User: "Tôi muốn nạp tiền"
AI: {"action": "navigate", "target": "deposit", "message": "Để nạp tiền, bạn cần chuyển từ ví MoMo vào Smart Finance. Tôi có thể đưa bạn đến trang Nạp tiền ngay — bạn chỉ cần bấm nút bên dưới nhé!"}

User: "Số dư của tôi là bao nhiêu?"
AI: {"action": "none", "message": "Số dư ví hiện tại của bạn là [X] VNĐ. Bạn có muốn xem chi tiết lịch sử giao dịch không?"}

User: "Cách chia tiền nhóm như thế nào?"
AI: {"action": "none", "message": "Để chia tiền trong nhóm, bạn vào tính năng Ví nhóm → chọn nhóm → bấm 'Chia tiền'. Nhập tổng chi phí, hệ thống sẽ tự chia đều cho tất cả thành viên và tạo danh sách nợ. Thành viên có thể bấm 'Thanh toán nợ' để trả."}

DANH SÁCH TRANG HỢP LỆ:
- home: Trang chủ, xem số dư
- budget: Quản lý ngân sách
- group_wallet: Ví nhóm
- settings: Cài đặt
- deposit: Nạp tiền từ MoMo
- transfer: Rút tiền ra MoMo
- send_money: Chuyển tiền nội bộ
- profile: Hồ sơ cá nhân
- notifications: Thông báo
- transaction_history: Lịch sử giao dịch

LƯU Ý:
1. Trả lời bằng Tiếng Việt, thân thiện và chuyên nghiệp
2. Sử dụng thông tin thực tế của user (số dư, giao dịch) khi có trong context
3. Khi đề xuất navigate, luôn giải thích ngắn tại sao và hỏi user xác nhận
4. KHÔNG tự động navigate — chỉ đề xuất, user quyết định
  ''';

  @override
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    required List<ChatMessage> history,
    required String userId,
  }) async {
    // Nếu là tin nhắn đầu tiên trong session → build & inject user context
    List<ChatMessage> effectiveHistory = history;
    if (history.isEmpty) {
      final userContext = await userContextBuilder.buildContext(userId);
      if (userContext.isNotEmpty) {
        debugPrint('[Gemini] Injecting user context for session: $sessionId');
        // Tạo một tin nhắn hệ thống giả (model role) chứa context
        // để Gemini nhận biết thông tin user mà không lộ ra UI
        effectiveHistory = [
          ChatMessage(
            id: 'ctx_$sessionId',
            content: 'SYSTEM_CONTEXT: $userContext',
            role: MessageRole.user,
            timestamp: DateTime.now(),
          ),
          ChatMessage(
            id: 'ctx_ack_$sessionId',
            content:
                '{"action": "none", "message": "Đã nhận thông tin. Tôi sẵn sàng hỗ trợ bạn!"}',
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
          ),
        ];
      }
    }

    // Lấy hoặc restore ChatSession từ cache
    final chatSession = sessionManager.getOrRestoreSession(
      sessionId,
      effectiveHistory,
    );

    try {
      debugPrint(
        '[Gemini] Đang gửi tin nhắn (session: $sessionId): "$message"',
      );
      final response = await chatSession.sendMessage(Content.text(message));
      final responseText = response.text;
      debugPrint('[Gemini] Phản hồi thô (Raw): $responseText');

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Parse JSON — thử clean nếu có markdown wrapper
      String cleanJson = responseText.trim();
      if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson
            .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
            .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
            .trim();
      }

      final Map<String, dynamic> jsonResponse = jsonDecode(cleanJson);
      debugPrint('[Gemini] Dữ liệu JSON đã parse: $jsonResponse');

      final replyMessage =
          jsonResponse['message'] as String? ??
          'Xin lỗi, tôi không thể xử lý yêu cầu.';
      final actionStr = jsonResponse['action'] as String?;
      final targetStr = jsonResponse['target'] as String?;

      AIAction? action;
      if (actionStr != null && actionStr != 'none') {
        action = AIAction.fromTarget(actionStr, targetStr);
      }

      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: replyMessage,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        action: action,
      );
    } catch (e) {
      debugPrint('[Gemini] Exception: $e');
      throw Exception('Lỗi khi giao tiếp với AI: $e');
    }
  }

  @override
  void removeSession(String sessionId) {
    sessionManager.removeSession(sessionId);
  }

  @override
  void clearSession(String sessionId) {
    sessionManager.clearSession(sessionId);
  }
}
