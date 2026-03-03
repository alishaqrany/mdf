import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/ai_entities.dart';
import '../bloc/ai_chat_bloc.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AiChatBloc>(),
      child: const _AiChatView(),
    );
  }
}

class _AiChatView extends StatefulWidget {
  const _AiChatView();

  @override
  State<_AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<_AiChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    context.read<AiChatBloc>().add(SendChatMessage(
          userId: userId,
          message: text,
        ));

    _controller.clear();
    _focusNode.requestFocus();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant', style: theme.textTheme.titleSmall),
                Text('Online',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.success)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: () {
              context.read<AiChatBloc>().add(ClearChat());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child: BlocConsumer<AiChatBloc, AiChatState>(
              listener: (context, state) {
                if (state is AiChatActive && state.messages.isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                }
              },
              builder: (context, state) {
                if (state is AiChatInitial) {
                  return _EmptyChat();
                }

                if (state is AiChatActive) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    itemCount:
                        state.messages.length + (state.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isTyping) {
                        return _TypingIndicator();
                      }
                      return _MessageBubble(
                        message: state.messages[index],
                        isDark: isDark,
                      );
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          // Input area
          _ChatInput(
            controller: _controller,
            focusNode: _focusNode,
            onSend: _sendMessage,
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

// ─── Empty Chat ───
class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 16),
            Text('AI Academic Assistant',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Ask me about your courses, grades, study tips, or anything academic!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(height: 24),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _SuggestionChip(text: 'What are my courses?'),
                _SuggestionChip(text: 'Show my grades'),
                _SuggestionChip(text: 'Study suggestions'),
                _SuggestionChip(text: 'ما هي درجاتي؟'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  const _SuggestionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      avatar: const Icon(Icons.auto_awesome, size: 16),
      backgroundColor: AppColors.primarySurface,
      onPressed: () {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.id : 0;
        context.read<AiChatBloc>().add(SendChatMessage(
              userId: userId,
              message: text,
            ));
      },
    );
  }
}

// ─── Message Bubble ───
class _MessageBubble extends StatelessWidget {
  final AiChatMessage message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return FadeInUp(
      duration: const Duration(milliseconds: 250),
      child: Align(
        alignment: isUser
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isUser
                ? AppColors.primary
                : isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 2),
              bottomRight: Radius.circular(isUser ? 2 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser && message.type == AiMessageType.error)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                ),
              SelectableText(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUser ? Colors.white : null,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ─── Typing Indicator ───
class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 600 + i * 200),
              builder: (context, value, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: 0.4 + value * 0.4),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

// ─── Chat Input ───
class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final bool isDark;

  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              maxLines: 3,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onSend,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child:
                    Icon(Icons.send_rounded, size: 22, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
