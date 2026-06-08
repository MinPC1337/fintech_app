import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../domain/entities/chat_message.dart';

/// Quản lý in-memory cache các [ChatSession] của Gemini SDK.
/// Mỗi [sessionId] tương ứng một [ChatSession] object, giúp SDK tích lũy
/// context mà không cần reload history mỗi lần gửi tin.
class GeminiSessionManager {
  final GenerativeModel _model;
  final Map<String, ChatSession> _sessions = {};

  GeminiSessionManager({required GenerativeModel model}) : _model = model;

  /// Lấy [ChatSession] từ cache nếu đã có.
  /// Nếu chưa có, tạo mới và restore từ [history] (lấy từ Firestore).
  ChatSession getOrRestoreSession(
    String sessionId,
    List<ChatMessage> history,
  ) {
    if (_sessions.containsKey(sessionId)) {
      debugPrint('[GeminiSessionManager] Reusing cached session: $sessionId');
      return _sessions[sessionId]!;
    }

    debugPrint(
      '[GeminiSessionManager] Restoring session: $sessionId '
      'with ${history.length} messages',
    );

    // Rebuild history từ Firestore messages (chỉ thực hiện một lần duy nhất)
    final chatHistory = history.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      } else {
        return Content.model([TextPart(msg.content)]);
      }
    }).toList();

    final session = _model.startChat(history: chatHistory);
    _sessions[sessionId] = session;
    return session;
  }

  /// Xóa session khỏi cache (dùng khi user xóa session).
  void removeSession(String sessionId) {
    _sessions.remove(sessionId);
    debugPrint('[GeminiSessionManager] Removed session: $sessionId');
  }

  /// Reset session (dùng khi user clear history) — tạo lại session rỗng.
  void clearSession(String sessionId) {
    _sessions.remove(sessionId);
    debugPrint('[GeminiSessionManager] Cleared session: $sessionId');
  }

  /// Xóa toàn bộ cache (dùng khi logout).
  void clearAll() {
    _sessions.clear();
    debugPrint('[GeminiSessionManager] Cleared all sessions');
  }
}
