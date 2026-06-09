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

  /// Index model đang được sử dụng.
  int _currentModelIndex = 0;

  /// Cache sessions theo sessionId.
  final Map<String, ChatSession> _sessions = {};

  GeminiSessionManager({required List<GenerativeModel> models})
      : assert(models.isNotEmpty, 'Phải có ít nhất 1 model'),
        _models = models;

  GenerativeModel get _currentModel => _models[_currentModelIndex];

  String get currentModelName {
    // GenerativeModel không expose tên model, nên track thủ công qua index
    const names = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-flash',
      'gemini-1.5-flash-8b',
    ];
    if (_currentModelIndex < names.length) return names[_currentModelIndex];
    return 'gemini-model-${_currentModelIndex + 1}';
  }

  /// Lấy [ChatSession] từ cache nếu đã có.
  /// Nếu chưa có, tạo mới và restore từ [history] (lấy từ Firestore).
  ChatSession getOrRestoreSession(
    String sessionId,
    List<ChatMessage> history,
  ) {
    if (_sessions.containsKey(sessionId)) {
      debugPrint(
        '[GeminiSessionManager] Reusing cached session: $sessionId '
        '(model: $currentModelName)',
      );
      return _sessions[sessionId]!;
    }

    return _createSession(sessionId, history);
  }

  ChatSession _createSession(String sessionId, List<ChatMessage> history) {
    debugPrint(
      '[GeminiSessionManager] Creating session: $sessionId '
      'with ${history.length} messages (model: $currentModelName)',
    );

    final chatHistory = history.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      } else {
        // Wrap lại dạng JSON để model nhất quán với system prompt
        final jsonWrapped =
            msg.content.startsWith('{')
                ? msg.content
                : '{"action": "none", "message": "${msg.content.replaceAll('"', '\\"')}"}';
        return Content.model([TextPart(jsonWrapped)]);
      }
    }).toList();

    final session = _currentModel.startChat(history: chatHistory);
    _sessions[sessionId] = session;
    return session;
  }

  /// Chuyển sang model tiếp theo trong fallback chain.
  /// Xóa session hiện tại để tạo lại với model mới.
  /// Trả về `true` nếu còn model để fallback, `false` nếu đã hết.
  bool switchToNextModel(String sessionId) {
    if (_currentModelIndex >= _models.length - 1) {
      debugPrint(
        '[GeminiSessionManager] Không còn model fallback nào! '
        'Đã thử hết ${_models.length} model.',
      );
      return false;
    }

    _currentModelIndex++;
    // Xóa session cũ để tạo lại với model mới
    _sessions.remove(sessionId);
    debugPrint(
      '[GeminiSessionManager] Chuyển sang model fallback: $currentModelName '
      '(index: $_currentModelIndex)',
    );
    return true;
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
    _currentModelIndex = 0; // reset về model mặc định
    debugPrint(
      '[GeminiSessionManager] Cleared all sessions, reset to primary model',
    );
  }
}
