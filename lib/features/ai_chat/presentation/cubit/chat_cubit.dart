import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_chat_history_usecase.dart';
import '../../domain/usecases/clear_chat_history_usecase.dart';
import '../../domain/usecases/watch_sessions_usecase.dart';
import '../../domain/usecases/create_session_usecase.dart';
import '../../domain/usecases/delete_session_usecase.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final ClearChatHistoryUseCase clearChatHistoryUseCase;
  final WatchSessionsUseCase watchSessionsUseCase;
  final CreateSessionUseCase createSessionUseCase;
  final DeleteSessionUseCase deleteSessionUseCase;

  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _messagesSubscription;

  List<ChatSession> _currentSessions = [];
  List<ChatMessage> _currentMessages = [];
  String? _currentUserId;
  String? _currentSessionId;

  ChatCubit({
    required this.sendMessageUseCase,
    required this.getChatHistoryUseCase,
    required this.clearChatHistoryUseCase,
    required this.watchSessionsUseCase,
    required this.createSessionUseCase,
    required this.deleteSessionUseCase,
  }) : super(ChatInitial());

  void init(String userId) {
    _currentUserId = userId;
    _sessionsSubscription?.cancel();
    
    emit(ChatLoading(
      sessions: _currentSessions, 
      currentSessionId: _currentSessionId, 
      messages: _currentMessages
    ));
    
    _sessionsSubscription = watchSessionsUseCase(userId).listen(
      (sessions) {
        _currentSessions = sessions;
        
        // Nếu chưa có session nào được chọn, chọn session đầu tiên
        // Nếu danh sách trống, tạo session mới
        if (sessions.isEmpty) {
          createNewSession();
        } else if (_currentSessionId == null || !sessions.any((s) => s.id == _currentSessionId)) {
          switchSession(sessions.first.id);
        } else {
          _emitLoaded();
        }
      },
      onError: (e) {
        emit(ChatError(
          message: e.toString(),
          sessions: _currentSessions,
          currentSessionId: _currentSessionId,
          messages: _currentMessages,
        ));
      },
    );
  }

  void _watchMessages(String sessionId) {
    if (_currentUserId == null) return;
    
    _messagesSubscription?.cancel();
    _messagesSubscription = getChatHistoryUseCase(_currentUserId!, sessionId).listen(
      (messages) {
        _currentMessages = messages;
        _emitLoaded();
      },
      onError: (e) {
        emit(ChatError(
          message: e.toString(),
          sessions: _currentSessions,
          currentSessionId: _currentSessionId,
          messages: _currentMessages,
        ));
      },
    );
  }

  void switchSession(String sessionId) {
    _currentSessionId = sessionId;
    _currentMessages = []; // Xóa tin nhắn cũ trước khi load tin mới
    emit(ChatLoading(
      sessions: _currentSessions, 
      currentSessionId: _currentSessionId, 
      messages: _currentMessages
    ));
    _watchMessages(sessionId);
  }

  Future<void> createNewSession() async {
    if (_currentUserId == null) return;
    
    emit(ChatLoading(
      sessions: _currentSessions, 
      currentSessionId: _currentSessionId, 
      messages: _currentMessages
    ));
    
    final result = await createSessionUseCase(_currentUserId!, 'Trò chuyện mới');
    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        sessions: _currentSessions,
        currentSessionId: _currentSessionId,
        messages: _currentMessages,
      )),
      (session) {
        switchSession(session.id);
      },
    );
  }

  Future<void> deleteSession(String sessionId) async {
    if (_currentUserId == null) return;
    
    emit(ChatLoading(
      sessions: _currentSessions, 
      currentSessionId: _currentSessionId, 
      messages: _currentMessages
    ));
    
    final result = await deleteSessionUseCase(_currentUserId!, sessionId);
    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        sessions: _currentSessions,
        currentSessionId: _currentSessionId,
        messages: _currentMessages,
      )),
      (_) {
        // Stream session sẽ tự động cập nhật và gọi lại switchSession nếu cần
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (_currentUserId == null || _currentSessionId == null || text.trim().isEmpty) return;

    emit(ChatLoading(
      sessions: _currentSessions,
      currentSessionId: _currentSessionId,
      messages: _currentMessages,
    ));
    
    final result = await sendMessageUseCase(
      message: text,
      history: _currentMessages,
      userId: _currentUserId!,
      sessionId: _currentSessionId!,
    );

    result.fold(
      (failure) {
        emit(ChatError(
          message: failure.message,
          sessions: _currentSessions,
          currentSessionId: _currentSessionId,
          messages: _currentMessages,
        ));
        _emitLoaded();
      },
      (_) {
        // Firestore stream tự cập nhật tin nhắn (bao gồm action field)
        // MessageBubble sẽ render ActionCard — user bấm mới navigate
      },
    );
  }

  Future<void> clearHistory() async {
    if (_currentUserId == null || _currentSessionId == null) return;
    
    emit(ChatLoading(
      sessions: _currentSessions,
      currentSessionId: _currentSessionId,
      messages: _currentMessages,
    ));
    
    final result = await clearChatHistoryUseCase(_currentUserId!, _currentSessionId!);
    
    result.fold(
      (failure) => emit(ChatError(
        message: failure.message,
        sessions: _currentSessions,
        currentSessionId: _currentSessionId,
        messages: _currentMessages,
      )),
      (_) {
        // Stream Firestore sẽ update UI
      },
    );
  }

  void _emitLoaded() {
    emit(ChatLoaded(
      sessions: _currentSessions,
      currentSessionId: _currentSessionId,
      messages: _currentMessages,
    ));
  }

  @override
  Future<void> close() {
    _sessionsSubscription?.cancel();
    _messagesSubscription?.cancel();
    return super.close();
  }
}
