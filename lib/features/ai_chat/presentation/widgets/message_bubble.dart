import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';
import '../utils/navigation_command_handler.dart';
import 'action_card.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? userAvatarUrl;
  final String aiAvatarAsset;

  const MessageBubble({
    super.key,
    required this.message,
    this.userAvatarUrl,
    this.aiAvatarAsset = 'assets/robot.png',
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[_buildAvatar(), const SizedBox(width: 8)],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(colors: [kCyan, kPurple])
                        : null,
                    color: isUser ? null : kThemeSurfaceSecondary,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: kThemeBorderDefault),
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            strong: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            em: TextStyle(
                              color: kTextPrimary.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                            ),
                            h1: const TextStyle(
                              color: kCyan,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: const TextStyle(
                              color: kCyan,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            listBullet: const TextStyle(
                              color: kCyan,
                              fontSize: 15,
                            ),
                            code: const TextStyle(
                              color: kCyan,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: kBgColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: kCyan.withValues(alpha: 0.3),
                              ),
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: kPurple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: kPurple,
                                  width: 3,
                                ),
                              ),
                            ),
                            blockquote: TextStyle(
                              color: kTextPrimary.withValues(alpha: 0.85),
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                            ),
                            horizontalRuleDecoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: kThemeBorderDefault,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          softLineBreak: true,
                          shrinkWrap: true,
                        ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(isUser: true),
              ],
            ],
          ),
          if (!isUser && message.action != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4),
              child: ActionCard(
                action: message.action!,
                onExecute: () =>
                    NavigationCommandHandler.handle(context, message.action!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({bool isUser = false}) {
    final double size = 32;

    if (isUser) {
      if (userAvatarUrl != null && userAvatarUrl!.isNotEmpty) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: NetworkImage(userAvatarUrl!),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
        );
      }

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Icon(Icons.person, size: 18, color: Colors.white),
      );
    }

    // Assistant / AI avatar from asset
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(aiAvatarAsset),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: kCyan.withValues(alpha: 0.5)),
      ),
    );
  }
}
