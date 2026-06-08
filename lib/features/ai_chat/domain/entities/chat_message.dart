import 'package:equatable/equatable.dart';
import 'ai_action.dart';

/// Vai trò trong cuộc hội thoại.
enum MessageRole { user, assistant }

/// Entity đại diện cho một tin nhắn trong cuộc chat.
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final AIAction? action;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.action,
  });

  @override
  List<Object?> get props => [id, content, role, timestamp, action];
}
