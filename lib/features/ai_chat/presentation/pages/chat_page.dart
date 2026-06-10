import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatCubit _chatCubit;
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _chatCubit = sl<ChatCubit>();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _chatCubit.init(_userId);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _chatCubit.close();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _chatCubit.sendMessage(text);
  }

  String _friendlyErrorMessage(String rawMessage) {
    final lower = rawMessage.toLowerCase();

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('internet')) {
      return 'Không thể kết nối mạng. Vui lòng kiểm tra Internet và thử lại.';
    }

    if (lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('resource_exhausted') ||
        lower.contains('429') ||
        lower.contains('throttl')) {
      return 'Dịch vụ chatbot đang quá tải hoặc đã hết hạn mức. Vui lòng thử lại sau vài phút.';
    }

    if (lower.contains('timeout')) {
      return 'Yêu cầu đã hết thời gian chờ. Vui lòng thử lại.';
    }

    if (lower.contains('high demand') ||
        lower.contains('503') ||
        lower.contains('server error') ||
        lower.contains('unavailable') ||
        lower.contains('temporarily unavailable') ||
        lower.contains('spikes in demand')) {
      return 'Dịch vụ chatbot hiện đang quá tải hoặc tạm ngưng. Vui lòng thử lại sau vài phút.';
    }

    if (lower.contains('empty response') ||
        lower.contains('empty response from ai') ||
        lower.contains('empty message')) {
      return 'Chatbot không trả lời được. Vui lòng thử lại.';
    }

    if (lower.contains('json') ||
        lower.contains('unexpected character') ||
        lower.contains('format exception') ||
        lower.contains('invalid json')) {
      return 'Đã xảy ra lỗi khi xử lý phản hồi từ chatbot. Vui lòng thử lại.';
    }

    return 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kThemeSurfaceSecondary,
        title: Text(title, style: const TextStyle(color: kTextPrimary)),
        content: Text(content, style: const TextStyle(color: kTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: kRose, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        backgroundColor: kBgColor,
        drawer: _buildDrawer(),
        appBar: _buildAppBar(context),
        body: BlocConsumer<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded ||
                state is ChatLoading ||
                state is ChatError) {
              Future.delayed(
                const Duration(milliseconds: 100),
                _scrollToBottom,
              );
            }
          },
          builder: (context, state) {
            List<dynamic> messages = [];
            bool isTyping = false;
            String? errorMessage;

            if (state is ChatLoaded) {
              messages = state.messages;
            } else if (state is ChatLoading) {
              messages = state.messages;
              isTyping = state.isTyping;
            } else if (state is ChatError) {
              messages = state.messages;
              errorMessage = _friendlyErrorMessage(state.message);
            }

            final itemCount =
                messages.length +
                (isTyping ? 1 : 0) +
                (errorMessage != null ? 1 : 0);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index == messages.length && isTyping) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TypingIndicator(),
                          ),
                        );
                      }

                      if (errorMessage != null &&
                          index == messages.length + (isTyping ? 1 : 0)) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: kRose.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: kRose.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                'Lỗi: $errorMessage',
                                style: const TextStyle(
                                  color: kRose,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      // Get avatar URL from AuthCubit (app user) or fallback to Firebase user photoURL
                      final authState = context.read<AuthCubit>().state;
                      String? avatarUrl;
                      if (authState is AuthSuccess) {
                        avatarUrl = authState.user.avatarUrl;
                      } else {
                        avatarUrl = FirebaseAuth.instance.currentUser?.photoURL;
                      }

                      return MessageBubble(
                        message: messages[index],
                        userAvatarUrl: avatarUrl,
                      );
                    },
                  ),
                ),
                _buildInputArea(),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 10),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: kGlassBg,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: kTextPrimary,
            ), // Màu icon menu
            title: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                String title = 'AI Trợ lý';
                if (state is ChatLoaded ||
                    state is ChatLoading ||
                    state is ChatError) {
                  final s = state as dynamic;
                  if (s.sessions.isNotEmpty && s.currentSessionId != null) {
                    dynamic currentSession;
                    for (final session in (s.sessions as List)) {
                      if ((session as dynamic).id == s.currentSessionId) {
                        currentSession = session;
                        break;
                      }
                    }
                    if (currentSession != null) {
                      title = currentSession.title;
                    }
                  }
                }

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kCyan.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: kCyan.withValues(alpha: 0.3)),
                      ),
                      child: Image.asset(
                        'assets/robot.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Smart Finance AI Assistant',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: kRose),
                tooltip: 'Xóa lịch sử phiên này',
                onPressed: () {
                  _showDeleteConfirmation(
                    context,
                    title: 'Xóa lịch sử trò chuyện',
                    content: 'Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện của phiên này không?',
                    onConfirm: () => _chatCubit.clearHistory(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: kTextPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: kBgColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // close drawer
                  _chatCubit.createNewSession();
                },
                icon: const Icon(Icons.add),
                label: const Text('Trò chuyện mới'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kThemeSurfaceSecondary,
                  foregroundColor: kTextPrimary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: kThemeBorderDefault),
                  ),
                ),
              ),
            ),
            const Divider(color: kThemeBorderDefault),
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                builder: (context, state) {
                  List<dynamic> sessions = [];
                  String? currentId;

                  if (state is ChatLoaded ||
                      state is ChatLoading ||
                      state is ChatError) {
                    final s = state as dynamic;
                    sessions = s.sessions;
                    currentId = s.currentSessionId;
                  }

                  if (sessions.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có phiên chat nào',
                        style: TextStyle(color: kTextSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isSelected = session.id == currentId;

                      return ListTile(
                        selected: isSelected,
                        selectedTileColor: kCyan.withValues(alpha: 0.1),
                        leading: const Icon(
                          Icons.chat_bubble_outline,
                          color: kTextSecondary,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? kCyan : kTextPrimary,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: kTextSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            _showDeleteConfirmation(
                              context,
                              title: 'Xóa phiên chat',
                              content: 'Bạn có chắc chắn muốn xóa vĩnh viễn phiên chat này không?',
                              onConfirm: () => _chatCubit.deleteSession(session.id),
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _chatCubit.switchSession(session.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kThemeSurfacePrimary,
        border: Border(top: BorderSide(color: kThemeBorderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: kThemeSurfaceSecondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kThemeBorderDefault),
              ),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: kTextPrimary),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: kTextSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [kCyan, kPurple]),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
