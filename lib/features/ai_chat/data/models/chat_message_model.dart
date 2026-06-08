import '../../domain/entities/ai_action.dart';
import '../../domain/entities/chat_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.action,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json, String id) {
    MessageRole role = MessageRole.user;
    if (json['role'] == 'assistant') {
      role = MessageRole.assistant;
    }

    AIAction? action;
    if (json['action'] != null) {
      final actionData = json['action'] as Map<String, dynamic>;
      final typeStr = actionData['type'] as String?;
      final targetStr = actionData['targetRoute'] as String?;
      
      final type = AIAction.parseType(typeStr);
      action = AIAction(
        type: type,
        targetRoute: targetStr,
        params: actionData['params'] as Map<String, dynamic>?,
      );
    }

    DateTime timestamp = DateTime.now();
    if (json['timestamp'] is Timestamp) {
      timestamp = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      timestamp = DateTime.tryParse(json['timestamp']) ?? DateTime.now();
    }

    return ChatMessageModel(
      id: id,
      content: json['content'] ?? '',
      role: role,
      timestamp: timestamp,
      action: action,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'role': role.name,
      'timestamp': FieldValue.serverTimestamp(),
      if (action != null)
        'action': {
          'type': action!.type.name,
          'targetRoute': action!.targetRoute,
          'params': action!.params,
        },
    };
  }

  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      role: entity.role,
      timestamp: entity.timestamp,
      action: entity.action,
    );
  }
}
