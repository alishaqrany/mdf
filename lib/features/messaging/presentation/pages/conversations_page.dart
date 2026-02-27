import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/message.dart';
import '../bloc/messaging_bloc.dart';

/// Conversations list page.
class ConversationsPage extends StatelessWidget {
  final int userId;

  const ConversationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MessagingBloc(repository: sl())
            ..add(LoadConversations(userId: userId)),
      child: Scaffold(
        appBar: AppBar(title: Text('messages.title'.tr())),
        body: BlocBuilder<MessagingBloc, MessagingState>(
          builder: (context, state) {
            if (state is MessagingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MessagingError) {
              return Center(child: Text(state.message));
            }
            if (state is ConversationsLoaded) {
              if (state.conversations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<MessagingBloc>().add(
                      LoadConversations(userId: userId),
                    );
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text('messages.no_messages'.tr()),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MessagingBloc>().add(
                    LoadConversations(userId: userId),
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  itemCount: state.conversations.length,
                  itemBuilder: (context, index) {
                    final conv = state.conversations[index];
                    return _ConversationTile(
                      conversation: conv,
                      userId: userId,
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final int userId;

  const _ConversationTile({required this.conversation, required this.userId});

  @override
  Widget build(BuildContext context) {
    final otherMember = conversation.members.isNotEmpty
        ? conversation.members.firstWhere(
            (m) => m.id != userId,
            orElse: () => conversation.members.first,
          )
        : null;
    final displayName =
        conversation.name ?? otherMember?.fullName ?? 'messages.title'.tr();
    final lastMessage = conversation.messages.isNotEmpty
        ? conversation.messages.last.text ?? ''
        : '';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: otherMember?.profileImageUrl != null
            ? NetworkImage(otherMember!.profileImageUrl!)
            : null,
        child: otherMember?.profileImageUrl == null
            ? Text(displayName.isNotEmpty ? displayName[0] : '?')
            : null,
      ),
      title: Text(
        displayName,
        style: conversation.unreadCount > 0
            ? const TextStyle(fontWeight: FontWeight.bold)
            : null,
      ),
      subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: conversation.unreadCount > 0
          ? CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            )
          : null,
      onTap: () {
        context.push(
          '/chat/${conversation.id}',
          extra: {
            'userId': userId,
            'title': displayName,
            'toUserId': otherMember?.id ?? 0,
          },
        );
      },
    );
  }
}
