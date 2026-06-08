import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/ai_action.dart';

abstract class GeminiRemoteDataSource {
  Future<ChatMessage> sendMessage(String message, List<ChatMessage> history);
}

class GeminiRemoteDataSourceImpl implements GeminiRemoteDataSource {
  final FirebaseAuth firebaseAuth;

  GeminiRemoteDataSourceImpl({required this.firebaseAuth});

  static const String _systemPrompt = '''
Bạn là trợ lý tài chính AI thông minh trong ứng dụng Fintech tên là "Smart Finance".
Mục tiêu của bạn là giúp người dùng quản lý tài chính, hiểu về các tính năng của app và điều hướng nhanh chóng.

QUY TẮC ĐỊNH DẠNG:
- KHI NGƯỜI DÙNG YÊU CẦU ĐIỀU HƯỚNG hoặc HÀNH ĐỘNG, bạn PHẢI trả về ĐÚNG MỘT JSON HỢP LỆ như sau, không kèm bất kỳ markdown nào:
{"action": "navigate", "target": "TÊN_TRANG_MỤC_TIÊU", "message": "Câu trả lời của bạn cho người dùng"}

- KHI CHỈ TRẢ LỜI CÂU HỎI THÔNG THƯỜNG, trả về JSON:
{"action": "none", "message": "Câu trả lời của bạn cho người dùng, giải thích chi tiết, thân thiện."}

Danh sách TÊN_TRANG_MỤC_TIÊU hợp lệ có trong app:
- home: Trang chủ, xem tổng quan
- budget: Quản lý ngân sách, thống kê chi tiêu
- group_wallet: Ví nhóm, chia tiền, đòi tiền, quỹ nhóm
- settings: Cài đặt ứng dụng
- deposit: Nạp tiền vào ví
- transfer: Rút tiền ra MoMo
- send_money: Chuyển tiền cho người dùng khác
- profile: Thông tin cá nhân
- notifications: Thông báo
- transaction_history: Lịch sử giao dịch

VÍ DỤ:
User: "Đưa tôi đến trang nạp tiền"
AI: {"action": "navigate", "target": "deposit", "message": "Được thôi, tôi sẽ đưa bạn đến trang Nạp tiền ngay nhé."}

User: "App này làm được gì?"
AI: {"action": "none", "message": "Chào bạn! Ứng dụng này giúp bạn quản lý tài chính cá nhân, ngân sách, chia sẻ ví nhóm và thực hiện các giao dịch như nạp, rút, chuyển tiền dễ dàng."}

LƯU Ý QUAN TRỌNG:
1. LUÔN LUÔN trả về JSON hợp lệ. Không markdown ```json ... ```, chỉ nội dung JSON raw.
2. Trả lời ngắn gọn, súc tích, chuyên nghiệp.
  ''';

  @override
  Future<ChatMessage> sendMessage(
    String message,
    List<ChatMessage> history,
  ) async {
    final googleAI = FirebaseAI.googleAI(auth: firebaseAuth);
    // Sử dụng model mới nhất theo hướng dẫn của AI Logic skill
    final model = googleAI.generativeModel(
      model: 'gemini-flash-latest',
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json', // Buộc trả về JSON
      ),
    );

    // Xây dựng history cho Gemini
    final chatHistory = history.map((msg) {
      if (msg.role == MessageRole.user) {
        return Content.text(msg.content);
      } else {
        // Assistant
        return Content.model([TextPart(msg.content)]);
      }
    }).toList();

    final chat = model.startChat(history: chatHistory);

    try {
      final response = await chat.sendMessage(Content.text(message));
      final responseText = response.text;

      if (responseText == null || responseText.isEmpty) {
        throw Exception("Empty response from AI");
      }

      // Parse JSON
      final Map<String, dynamic> jsonResponse = jsonDecode(responseText);

      final replyMessage =
          jsonResponse['message'] as String? ??
          "Xin lỗi, tôi không thể xử lý yêu cầu.";
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
    } catch (e) {
      throw Exception("Lỗi khi giao tiếp với AI: \$e");
    }
  }
}
