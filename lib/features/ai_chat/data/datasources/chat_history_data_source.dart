import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';

abstract class ChatHistoryDataSource {
  Stream<List<ChatSessionModel>> watchSessions(String userId);
  Future<ChatSessionModel> createSession(String userId, String title);
  Future<void> deleteSession(String userId, String sessionId);
  Future<void> updateSessionTitle(String userId, String sessionId, String title);

  Stream<List<ChatMessageModel>> watchChatHistory(String userId, String sessionId);
  Future<void> saveMessage(String userId, String sessionId, ChatMessageModel message);
  Future<void> clearHistory(String userId, String sessionId);
}

class ChatHistoryDataSourceImpl implements ChatHistoryDataSource {
  final FirebaseFirestore firestore;

  ChatHistoryDataSourceImpl({required this.firestore});

  @override
  Stream<List<ChatSessionModel>> watchSessions(String userId) {
    return firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatSessionModel.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<ChatSessionModel> createSession(String userId, String title) async {
    final docRef = firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc();
    
    final session = ChatSessionModel(
      id: docRef.id,
      title: title,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(session.toJson());
    return session;
  }

  @override
  Future<void> deleteSession(String userId, String sessionId) async {
    // 1. Delete all messages in session
    await clearHistory(userId, sessionId);
    
    // 2. Delete session doc
    await firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .delete();
  }

  @override
  Future<void> updateSessionTitle(String userId, String sessionId, String title) async {
    await firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<ChatMessageModel>> watchChatHistory(String userId, String sessionId) {
    return firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
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
  Future<void> saveMessage(String userId, String sessionId, ChatMessageModel message) async {
    final docRef = firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .doc(message.id);
    await docRef.set(message.toJson());
    
    // Update session updatedAt
    await firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .update({'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> clearHistory(String userId, String sessionId) async {
    final snapshot = await firestore
        .collection('chat_history')
        .doc(userId)
        .collection('sessions')
        .doc(sessionId)
        .collection('messages')
        .get();

    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
