import 'package:equatable/equatable.dart';
import '../../domain/entities/ai_action.dart';
import '../../domain/entities/chat_message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatActionRequested extends ChatState {
  final AIAction action;
  final List<ChatMessage> messages;

  const ChatActionRequested(this.action, this.messages);

  @override
  List<Object?> get props => [action, messages];
}
