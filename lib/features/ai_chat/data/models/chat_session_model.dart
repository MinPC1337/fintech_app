import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json, String id) {
    DateTime created = DateTime.now();
    if (json['createdAt'] is Timestamp) {
      created = (json['createdAt'] as Timestamp).toDate();
    }
    
    DateTime updated = DateTime.now();
    if (json['updatedAt'] is Timestamp) {
      updated = (json['updatedAt'] as Timestamp).toDate();
    }

    return ChatSessionModel(
      id: id,
      title: json['title'] ?? 'Trò chuyện mới',
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
