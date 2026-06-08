import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_action.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_chat_history_usecase.dart';
import '../../domain/usecases/clear_chat_history_usecase.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final ClearChatHistoryUseCase clearChatHistoryUseCase;

  StreamSubscription? _historySubscription;
  List<ChatMessage> _currentMessages = [];
  String? _currentUserId;

  ChatCubit({
    required this.sendMessageUseCase,
    required this.getChatHistoryUseCase,
    required this.clearChatHistoryUseCase,
  }) : super(ChatInitial());

  void init(String userId) {
    _currentUserId = userId;
    _historySubscription?.cancel();
    emit(ChatLoading());
    
    _historySubscription = getChatHistoryUseCase(userId).listen(
      (messages) {
        _currentMessages = messages;
        emit(ChatLoaded(messages));
      },
      onError: (e) {
        emit(ChatError(e.toString()));
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (_currentUserId == null || text.trim().isEmpty) return;

    // Hiển thị loading trong khi chờ AI (không cập nhật message vì Stream Firestore sẽ tự fetch)
    emit(ChatLoading());
    
    final result = await sendMessageUseCase(
      message: text,
      history: _currentMessages,
      userId: _currentUserId!,
    );

    result.fold(
      (failure) {
        emit(ChatError(failure.message));
        // Khôi phục lại trạng thái loaded
        emit(ChatLoaded(_currentMessages));
      },
      (aiMessage) {
        // Nếu AI trả về có action, thì emit ActionRequested để UI chuyển trang
        if (aiMessage.action != null && aiMessage.action!.type != AIActionType.none) {
          emit(ChatActionRequested(aiMessage.action!, _currentMessages));
        } else {
          // Stream sẽ tự động update
        }
      },
    );
  }

  Future<void> clearHistory() async {
    if (_currentUserId == null) return;
    
    emit(ChatLoading());
    final result = await clearChatHistoryUseCase(_currentUserId!);
    
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (_) {
        _currentMessages = [];
        emit(ChatLoaded(const []));
      },
    );
  }

  @override
  Future<void> close() {
    _historySubscription?.cancel();
    return super.close();
  }
}
