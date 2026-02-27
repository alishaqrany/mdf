import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/message.dart';
import '../bloc/messaging_bloc.dart';

/// Chat page showing messages in a conversation with send functionality.
class ChatPage extends StatefulWidget {
  final int conversationId;
  final int userId;
  final int toUserId;
  final String title;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.userId,
    required this.toUserId,
    required this.title,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgController = TextEditingController();
  late final MessagingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MessagingBloc(repository: sl())
      ..add(
        LoadMessages(
          conversationId: widget.conversationId,
          userId: widget.userId,
        ),
      );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Column(
          children: [
            // Messages
            Expanded(
              child: BlocConsumer<MessagingBloc, MessagingState>(
                listener: (context, state) {
                  if (state is MessageSent) {
                    _msgController.clear();
                    _bloc.add(
                      LoadMessages(
                        conversationId: widget.conversationId,
                        userId: widget.userId,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is MessagingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MessagesLoaded) {
                    if (state.messages.isEmpty) {
                      return Center(child: Text('messages.no_messages'.tr()));
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final msg =
                            state.messages[state.messages.length - 1 - index];
                        return _MessageBubble(
                          message: msg,
                          isMe: msg.userIdFrom == widget.userId,
                        );
                      },
                    );
                  }
                  if (state is MessagingError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'messages.type_message'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _bloc.add(SendMessageEvent(toUserId: widget.toUserId, message: text));
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Text(
          message.text ?? '',
          style: TextStyle(
            color: isMe
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
