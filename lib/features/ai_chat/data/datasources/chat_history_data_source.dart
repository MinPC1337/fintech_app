import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';

abstract class ChatHistoryDataSource {
  Stream<List<ChatMessageModel>> watchChatHistory(String userId);
  Future<void> saveMessage(String userId, ChatMessageModel message);
  Future<void> clearHistory(String userId);
}

class ChatHistoryDataSourceImpl implements ChatHistoryDataSource {
  final FirebaseFirestore firestore;

  ChatHistoryDataSourceImpl({required this.firestore});

  @override
  Stream<List<ChatMessageModel>> watchChatHistory(String userId) {
    return firestore
        .collection('chat_history')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessageModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<void> saveMessage(String userId, ChatMessageModel message) async {
    final docRef = firestore
        .collection('chat_history')
        .doc(userId)
        .collection('messages')
        .doc(message.id);
    await docRef.set(message.toJson());
  }

  @override
  Future<void> clearHistory(String userId) async {
    final snapshot = await firestore
        .collection('chat_history')
        .doc(userId)
        .collection('messages')
        .get();

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
