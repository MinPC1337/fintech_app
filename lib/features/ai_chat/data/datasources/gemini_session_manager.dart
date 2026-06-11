import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/chat_message.dart';

/// Quản lý in-memory cache các [ChatSession] của Gemini SDK.
///
/// Hỗ trợ:
/// - Fallback chain: khi model hiện tại bị lỗi quota/rate-limit,
///   tự động chuyển sang model tiếp theo trong danh sách.
/// - Function Calling: tự động inject [AiFunctionDefinitions.appDataTool]
///   vào tất cả [GenerativeModel] để AI có thể query dữ liệu thực tế.
class GeminiSessionManager {
  /// Danh sách model theo thứ tự ưu tiên (index 0 = ưu tiên nhất).
  final List<GenerativeModel> _models;

  /// Cache sessions theo sessionId.
  final Map<String, ChatSession> _sessions = {};

  /// Lưu index model đang dùng cho mỗi session.
  final Map<String, int> _sessionModelIndices = {};

  GeminiSessionManager({required List<GenerativeModel> models})
    : assert(models.isNotEmpty, 'Phải có ít nhất 1 model'),
      _models = models;

  int _getModelIndex(String sessionId) => _sessionModelIndices[sessionId] ?? 0;

  GenerativeModel _getModel(String sessionId) => _models[_getModelIndex(sessionId)];

  String currentModelName(String sessionId) {
    // GenerativeModel không expose tên model, nên track thủ công qua index
    const names = [
      'gemini-1.5-flash',
      'gemini-2.0-flash',
      'gemini-2.5-flash',
      'gemini-3.5-flash',
    ];
    final idx = _getModelIndex(sessionId);
    if (idx < names.length) return names[idx];
    return 'gemini-model-${idx + 1}';
  }

  /// Lấy [ChatSession] từ cache nếu đã có.
  /// Nếu chưa có, tạo mới và restore từ [history] (lấy từ Firestore).
  ChatSession getOrRestoreSession(String sessionId, List<ChatMessage> history) {
    if (_sessions.containsKey(sessionId)) {
      debugPrint(
        '[GeminiSessionManager] Reusing cached session: $sessionId '
        '(model: ${currentModelName(sessionId)})',
      );
      return _sessions[sessionId]!;
    }

    return _createSession(sessionId, history);
  }

  ChatSession _createSession(String sessionId, List<ChatMessage> history) {
    debugPrint(
      '[GeminiSessionManager] Creating session: $sessionId '
      'with ${history.length} messages (model: ${currentModelName(sessionId)})',
    );

    final chatHistory = history.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      } else {
        // Wrap lại dạng JSON để model nhất quán với system prompt
        final jsonWrapped = msg.content.startsWith('{')
            ? msg.content
            : '{"action": "none", "message": "${msg.content.replaceAll('"', '\\"')}"}';
        return Content.model([TextPart(jsonWrapped)]);
      }
    }).toList();

    final session = _getModel(sessionId).startChat(history: chatHistory);
    _sessions[sessionId] = session;
    return session;
  }

  /// Chuyển sang model tiếp theo trong fallback chain.
  /// Xóa session hiện tại để tạo lại với model mới.
  /// Trả về `true` nếu còn model để fallback, `false` nếu đã hết.
  bool switchToNextModel(String sessionId) {
    final currentIdx = _getModelIndex(sessionId);
    if (currentIdx >= _models.length - 1) {
      debugPrint(
        '[GeminiSessionManager] Không còn model fallback nào! '
        'Đã thử hết ${_models.length} model.',
      );
      return false;
    }

    _sessionModelIndices[sessionId] = currentIdx + 1;
    // Xóa session cũ để tạo lại với model mới
    _sessions.remove(sessionId);
    debugPrint(
      '[GeminiSessionManager] Chuyển sang model fallback: ${currentModelName(sessionId)} '
      '(index: ${currentIdx + 1})',
    );
    return true;
  }

  /// Reset model ưu tiên nhất cho session (thường dùng trước khi bắt đầu tin nhắn mới).
  void resetToPrimaryModel(String sessionId) {
    if (_sessionModelIndices[sessionId] != 0) {
      _sessionModelIndices[sessionId] = 0;
      _sessions.remove(sessionId);
      debugPrint('[GeminiSessionManager] Reset session $sessionId về model ưu tiên nhất (index: 0)');
    }
  }

  /// Lấy session mới với model tiếp theo (sau khi switchToNextModel).
  ChatSession getOrRestoreSessionWithNewModel(
    String sessionId,
    List<ChatMessage> history,
  ) {
    return _createSession(sessionId, history);
  }

  /// Xóa session khỏi cache (dùng khi user xóa session).
  void removeSession(String sessionId) {
    _sessions.remove(sessionId);
    _sessionModelIndices.remove(sessionId);
    debugPrint('[GeminiSessionManager] Removed session: $sessionId');
  }

  /// Reset session (dùng khi user clear history) — tạo lại session rỗng.
  void clearSession(String sessionId) {
    _sessions.remove(sessionId);
    _sessionModelIndices.remove(sessionId);
    debugPrint('[GeminiSessionManager] Cleared session: $sessionId');
  }

  /// Xóa toàn bộ cache (dùng khi logout).
  void clearAll() {
    _sessions.clear();
    _sessionModelIndices.clear();
    debugPrint(
      '[GeminiSessionManager] Cleared all sessions, reset to primary model',
    );
  }
}
