import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_action.dart';
import 'gemini_session_manager.dart';
import 'user_context_builder.dart';
import 'ai_function_handler.dart';

abstract class GeminiRemoteDataSource {
  /// Gửi [message] trong phiên [sessionId].
  /// [history] được dùng để restore session nếu chưa có trong cache.
  /// [userId] dùng để build user context và execute function calls.
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
  final AiFunctionHandler functionHandler;

  GeminiRemoteDataSourceImpl({
    required this.sessionManager,
    required this.userContextBuilder,
    required this.functionHandler,
  });

  /// Cache knowledge base sau khi load lần đầu (tránh đọc asset nhiều lần).
  static String? _cachedKnowledgeBase;

  // ────────────────────────────────────────────────────
  // System Prompt (load từ asset)
  // ────────────────────────────────────────────────────

  /// Load knowledge base từ asset và build system prompt hoàn chỉnh.
  static Future<String> buildSystemPrompt() async {
    _cachedKnowledgeBase ??= await rootBundle.loadString(
      'assets/ai/knowledge_base.md',
    );

    return '''
Bạn là trợ lý AI thông minh trong ứng dụng "Smart Finance" — ứng dụng quản lý tài chính cá nhân và nhóm dành cho người dùng Việt Nam.

═══════════════════════════════════════
TÀI LIỆU ỨNG DỤNG (KNOWLEDGE BASE)
═══════════════════════════════════════

${_cachedKnowledgeBase!}

═══════════════════════════════════════
KHẢ NĂNG ĐẶC BIỆT — FUNCTION CALLING
═══════════════════════════════════════

Bạn có thể gọi các function sau để lấy dữ liệu THỰC TẾ, CẬP NHẬT của user:

• getWalletBalance() — Số dư ví cá nhân hiện tại
• getRecentTransactions(limit, type) — Lịch sử giao dịch gần đây
• getBudgetStatus() — Trạng thái ngân sách tháng này
• getGroupWallets() — Danh sách ví nhóm đang tham gia
• getPendingDebts() — Nợ chưa thanh toán (đi & về)

Khi nào nên gọi function:
- User hỏi về số dư, tiền trong ví → getWalletBalance()
- User hỏi về giao dịch, lịch sử → getRecentTransactions()
- User hỏi về ngân sách, chi tiêu tháng này → getBudgetStatus()
- User hỏi về nhóm của mình → getGroupWallets()
- User hỏi về nợ, ai nợ tôi, tôi nợ ai → getPendingDebts()

═══════════════════════════════════════
QUY TẮC TRẢ LỜI
═══════════════════════════════════════

QUAN TRỌNG: LUÔN trả về đúng một JSON hợp lệ, KHÔNG có markdown, KHÔNG có ```json.

Khi người dùng hỏi về tính năng, hướng dẫn, tư vấn tài chính → trả về:
{"action": "none", "message": "Câu trả lời đầy đủ, thân thiện, dễ hiểu"}

Khi người dùng muốn đi đến một trang cụ thể → GỢI Ý và hỏi xác nhận:
{"action": "navigate", "target": "TÊN_TRANG", "message": "Giải thích + hỏi xác nhận"}

Ví dụ navigate:
User: "Tôi muốn nạp tiền"
AI: {"action": "navigate", "target": "deposit", "message": "Để nạp tiền, bạn cần chuyển từ ví MoMo vào Smart Finance. Tôi có thể đưa bạn đến trang Nạp tiền ngay — bạn chỉ cần bấm nút bên dưới nhé!"}

DANH SÁCH TRANG HỢP LỆ:
- home, budget, group_wallet, settings, deposit, transfer, send_money, profile, notifications, transaction_history

QUY TẮC QUAN TRỌNG:
1. Trả lời bằng Tiếng Việt, thân thiện và chuyên nghiệp
2. Sử dụng thông tin thực tế từ context hoặc function call khi user hỏi dữ liệu
3. KHÔNG tự bịa số tiền, giao dịch — hãy gọi function để lấy dữ liệu thật
4. Khi đề xuất navigate, luôn hỏi xác nhận trước
5. KHÔNG tự động thực hiện giao dịch — chỉ hướng dẫn và navigate
6. Nếu câu hỏi không liên quan đến app, nhẹ nhàng từ chối và đề xuất hỏi về Smart Finance
''';
  }

  // ────────────────────────────────────────────────────
  // sendMessage — Main entry point
  // ────────────────────────────────────────────────────

  @override
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    required List<ChatMessage> history,
    required String userId,
  }) async {
    // Nếu là tin nhắn đầu tiên trong session → inject user context
    List<ChatMessage> effectiveHistory = history;
    if (history.isEmpty) {
      final userContext = await userContextBuilder.buildContext(userId);
      if (userContext.isNotEmpty) {
        debugPrint('[Gemini] Injecting user context for session: $sessionId');
        effectiveHistory = [
          ChatMessage(
            id: 'ctx_$sessionId',
            content: 'SYSTEM_CONTEXT:\n$userContext',
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

    return await _sendWithFallback(
      message: message,
      sessionId: sessionId,
      history: effectiveHistory,
      userId: userId,
    );
  }

  // ────────────────────────────────────────────────────
  // Fallback chain (quota/rate-limit)
  // ────────────────────────────────────────────────────

  Future<ChatMessage> _sendWithFallback({
    required String message,
    required String sessionId,
    required List<ChatMessage> history,
    required String userId,
    int attempt = 0,
  }) async {
    final chatSession = sessionManager.getOrRestoreSession(sessionId, history);
    debugPrint(
      '[Gemini] Gửi (attempt ${attempt + 1}, '
      'model: ${sessionManager.currentModelName}): "$message"',
    );

    try {
      final response = await chatSession.sendMessage(Content.text(message));
      return await _handleResponse(
        response: response,
        userId: userId,
        chatSession: chatSession,
        originalMessage: message,
      );
    } catch (e) {
      debugPrint('[Gemini] Exception (attempt ${attempt + 1}): $e');

      if (_isQuotaOrRateLimitError(e.toString()) ||
          e.toString().contains('thought_signature')) {
        debugPrint('[Gemini] Quota/rate-limit error → thử model tiếp theo...');
        final hasFallback = sessionManager.switchToNextModel(sessionId);
        if (hasFallback) {
          return await _sendWithFallback(
            message: message,
            sessionId: sessionId,
            history: history,
            userId: userId,
            attempt: attempt + 1,
          );
        }
        throw Exception(
          'Tất cả model đều bị giới hạn quota. Vui lòng thử lại sau ít phút.',
        );
      }

      throw Exception('Lỗi khi giao tiếp với AI: $e');
    }
  }

  // ────────────────────────────────────────────────────
  // Response handler — xử lý cả FunctionCall và text
  // ────────────────────────────────────────────────────

  /// Xử lý response từ Gemini.
  /// Nếu Gemini trả về FunctionCall → execute → gửi lại kết quả → lấy text response.
  /// Nếu Gemini trả về text → parse JSON như bình thường.
  Future<ChatMessage> _handleResponse({
    required GenerateContentResponse response,
    required String userId,
    required ChatSession chatSession,
    required String originalMessage,
    int functionCallDepth = 0,
  }) async {
    // Giới hạn vòng lặp function call tối đa 3 lần để tránh infinite loop
    if (functionCallDepth >= 3) {
      debugPrint(
        '[Gemini] Max function call depth reached, forcing text response',
      );
      throw Exception('Quá nhiều function calls liên tiếp.');
    }

    // Kiểm tra có FunctionCall không
    final candidates = response.candidates;
    if (candidates.isEmpty) {
      throw Exception('Empty response from AI');
    }

    final firstCandidate = candidates.first;
    final parts = firstCandidate.content.parts;

    // Tìm FunctionCall parts
    final functionCallParts = parts.whereType<FunctionCall>().toList();

    if (functionCallParts.isNotEmpty) {
      // AI muốn gọi function → execute và gửi kết quả lại
      debugPrint(
        '[Gemini] AI yêu cầu ${functionCallParts.length} function call(s)',
      );

      final functionResponseParts = <FunctionResponse>[];

      for (final funcCall in functionCallParts) {
        debugPrint('[Gemini] Function call: ${funcCall.name}');
        final result = await functionHandler.execute(
          funcCall.name,
          funcCall.args,
          userId,
        );
        debugPrint('[Gemini] Function result: $result');

        functionResponseParts.add(
          FunctionResponse(funcCall.name, {'result': result}),
        );
      }

      // Gửi kết quả function về cho Gemini để nó tạo text response
      final functionResultResponse = await chatSession.sendMessage(
        Content.functionResponses(functionResponseParts),
      );

      // Đệ quy để xử lý response tiếp theo (Gemini có thể gọi function nữa)
      return _handleResponse(
        response: functionResultResponse,
        userId: userId,
        chatSession: chatSession,
        originalMessage: originalMessage,
        functionCallDepth: functionCallDepth + 1,
      );
    }

    // Không có FunctionCall → đây là text response cuối cùng
    final responseText = response.text;
    debugPrint('[Gemini] Phản hồi thô: $responseText');

    if (responseText == null || responseText.isEmpty) {
      throw Exception('Empty response from AI');
    }

    return _parseResponse(responseText);
  }

  // ────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────

  bool _isQuotaOrRateLimitError(String errorStr) {
    final lower = errorStr.toLowerCase();
    return lower.contains('429') ||
        lower.contains('quota') ||
        lower.contains('rate') ||
        lower.contains('resource_exhausted') ||
        lower.contains('too many requests') ||
        lower.contains('rateerror');
  }

  /// Parse JSON response từ Gemini thành [ChatMessage].
  ChatMessage _parseResponse(String responseText) {
    // Clean nếu có markdown wrapper
    String cleanJson = responseText.trim();
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson
          .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
          .trim();
    }

    Map<String, dynamic> jsonResponse;
    try {
      jsonResponse = jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      // Nếu parse JSON thất bại, wrap text thô thành JSON
      debugPrint('[Gemini] JSON parse failed, using raw text: $e');
      jsonResponse = {'action': 'none', 'message': cleanJson};
    }

    debugPrint('[Gemini] JSON đã parse: $jsonResponse');

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
