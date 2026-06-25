import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_action.dart';
import 'user_context_builder.dart';

abstract class RagRemoteDataSource {
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    required List<ChatMessage> history,
    required String userId,
  });
}

class RagRemoteDataSourceImpl implements RagRemoteDataSource {
  final UserContextBuilder userContextBuilder;
  final http.Client client;

  // Tự động nhận diện nền tảng để dùng đúng IP
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/chat';
    // Sử dụng IP mạng LAN thật của máy tính (hỗ trợ cả máy ảo và điện thoại thật)
    if (Platform.isAndroid || Platform.isIOS) return 'http://192.168.2.28:8000/api/chat';
    return 'http://127.0.0.1:8000/api/chat';
  }

  RagRemoteDataSourceImpl({
    required this.userContextBuilder,
    required this.client,
  });

  @override
  Future<ChatMessage> sendMessage({
    required String message,
    required String sessionId,
    required List<ChatMessage> history,
    required String userId,
  }) async {
    try {
      // 1. Build real-time user context
      final userContext = await userContextBuilder.buildContext(userId);

      // 2. Format history into JSON format expected by Python backend
      final historyList = history.map((msg) {
        return {
          'role': msg.role == MessageRole.user ? 'user' : 'assistant',
          'content': msg.content,
        };
      }).toList();

      // 3. Prepare payload
      final payload = {
        'question': message,
        'history': historyList,
        'user_context': userContext,
      };

      debugPrint('[RAG Chatbot] Sending payload: ${jsonEncode(payload)}');

      // 4. Send POST request with a 120-second timeout
      final response = await client
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 5000),
            onTimeout: () {
              throw Exception(
                'Yêu cầu tới AI Chatbot quá hạn (Timeout sau 120s). Bạn vui lòng thử lại nhé!',
              );
            },
          );

      if (response.statusCode != 200) {
        throw Exception(
          'Server returned ${response.statusCode}: ${response.body}',
        );
      }

      // 5. Parse response
      // Expecting: {"answer": "{\"action\": \"...\", \"message\": \"...\"}"}
      final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
      final answerString = responseBody['answer'] as String?;

      if (answerString == null || answerString.isEmpty) {
        throw Exception('Empty answer from server');
      }

      return _parseResponse(answerString);
    } catch (e) {
      debugPrint('[RAG Chatbot] Exception: $e');
      throw Exception('Lỗi khi giao tiếp với AI: $e');
    }
  }

  /// Parse JSON response from AI into [ChatMessage].
  ChatMessage _parseResponse(String responseText) {
    String cleanJson = responseText.trim();
    if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson
          .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
          .trim();
    }

    Map<String, dynamic> jsonResponse;
    try {
      jsonResponse = jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[RAG Chatbot] JSON parse failed, using raw text: $e');
      jsonResponse = {'action': 'none', 'message': cleanJson};
    }

    debugPrint('[RAG Chatbot] Parsed JSON: $jsonResponse');

    final replyMessage =
        jsonResponse['message'] as String? ??
        'Xin lỗi, tôi không thể xử lý yêu cầu.';
    final actionStr = jsonResponse['action'] as String?;
    final targetStr = jsonResponse['target'] as String?;

    AIAction? action;
    if (actionStr != null && actionStr != 'none') {
      action = AIAction.fromTarget(actionStr, targetStr);
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: replyMessage,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      action: action,
    );
  }
}
