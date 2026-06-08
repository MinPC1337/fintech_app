import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_session.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final List<ChatMessage> messages;

  const ChatLoading({
    this.sessions = const [],
    this.currentSessionId,
    this.messages = const [],
  });

  @override
  List<Object?> get props => [sessions, currentSessionId, messages];
}

class ChatLoaded extends ChatState {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final List<ChatMessage> messages;

  const ChatLoaded({
    required this.sessions,
    this.currentSessionId,
    required this.messages,
  });

  @override
  List<Object?> get props => [sessions, currentSessionId, messages];
}

class ChatError extends ChatState {
  final String message;
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final List<ChatMessage> messages;

  const ChatError({
    required this.message,
    this.sessions = const [],
    this.currentSessionId,
    this.messages = const [],
  });

  @override
  List<Object?> get props => [message, sessions, currentSessionId, messages];
}


