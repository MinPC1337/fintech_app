import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../ai_chat/presentation/pages/chat_page.dart';

class AiInsightCard extends StatelessWidget {
  final String userId;

  const AiInsightCard({super.key, required this.userId});

  Future<String?> _getLatestInsight() async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Lấy session mới nhất
      final sessionQuery = await firestore
          .collection('chat_history')
          .doc(userId)
          .collection('sessions')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (sessionQuery.docs.isEmpty) return null;
      final sessionId = sessionQuery.docs.first.id;

      // Lấy tin nhắn AI mới nhất
      final messageQuery = await firestore
          .collection('chat_history')
          .doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .collection('messages')
          .where('role', isEqualTo: 'assistant')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (messageQuery.docs.isEmpty) return null;

      // Lấy ngẫu nhiên hoặc mới nhất. Ở đây lấy tin mới nhất (index 0).
      final content = messageQuery.docs.first.data()['content'] as String?;
      if (content == null || content.isEmpty) return null;

      // Lọc các tin nhắn ngắn gọn (bỏ qua nếu là markdown quá dài hoặc json)
      // Để đơn giản, cứ lấy và cắt ngắn.
      final cleanText = content.replaceAll(RegExp(r'\n+'), ' ').trim();
      return cleanText.length > 70
          ? '${cleanText.substring(0, 70)}...'
          : cleanText;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatPage()),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kCyan.withValues(alpha: 0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E293B).withValues(alpha: 0.8),
              kPurple.withValues(alpha: 0.1),
              kCyan.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: kCyan.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPurple.withValues(alpha: 0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kCyan.withValues(alpha: 0.2),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: kCyan, size: 14),
                      const SizedBox(width: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [kCyan, kPurple],
                        ).createShader(bounds),
                        child: const Text(
                          'AI Insight',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: kCyan.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/robot.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.smart_toy_rounded,
                                  color: kCyan,
                                  size: 28,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FutureBuilder<String?>(
                            future: _getLatestInsight(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Text(
                                  'Đang tải gợi ý từ AI...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                );
                              }
                              final insight = snapshot.data;
                              if (insight != null && insight.isNotEmpty) {
                                return Text(
                                  '💡 "$insight"',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              return RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    height: 1.5,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Trợ lý ảo AI giúp bạn '),
                                    TextSpan(
                                      text: 'tư vấn quản lý chi tiêu',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: ' và '),
                                    TextSpan(
                                      text: 'cảnh báo ngân sách',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' thông minh.\nChạm để chat ngay!',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
