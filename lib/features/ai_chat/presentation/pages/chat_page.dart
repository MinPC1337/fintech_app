import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../injection_container.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../utils/navigation_command_handler.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _chatCubit,
      child: Scaffold(
        backgroundColor: kBgColor,
        appBar: _buildAppBar(context),
        body: BlocConsumer<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state is ChatActionRequested) {
              // Thực thi navigation
              NavigationCommandHandler.handle(context, state.action);
            }
            if (state is ChatLoaded || state is ChatActionRequested) {
              Future.delayed(
                const Duration(milliseconds: 100),
                _scrollToBottom,
              );
            }
          },
          builder: (context, state) {
            List<dynamic> messages = [];
            bool isLoading = false;

            if (state is ChatLoaded) {
              messages = state.messages;
            } else if (state is ChatActionRequested) {
              messages = state.messages;
            } else if (state is ChatLoading) {
              // Lấy list cũ ra từ _chatCubit._currentMessages?
              // Không thể truy cập private, vậy nên state should emit old messages if we want to retain them.
              // Tuy nhiên do dùng Stream Firestore, khi loading nó vẫn sẽ hiển thị UI message trống nếu chưa có.
              // Để UI mượt, chúng ta lấy message hiện tại lưu ở _chatCubit
              isLoading = true;
            } else if (state is ChatError) {
              return Center(
                child: Text(
                  'Lỗi: \${state.message}',
                  style: const TextStyle(color: kRose),
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: messages.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TypingIndicator(),
                          ),
                        );
                      }
                      return MessageBubble(message: messages[index]);
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: kTextPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kCyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: kCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.smart_toy, color: kCyan, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Trợ lý',
                      style: TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Smart Finance Assistant',
                      style: TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: kRose),
                tooltip: 'Xóa lịch sử chat',
                onPressed: () {
                  _chatCubit.clearHistory();
                },
              ),
            ],
          ),
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
