import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/message.dart';
import '../bloc/messaging_bloc.dart';

/// Conversations list page with search.
class ConversationsPage extends StatefulWidget {
  final int userId;

  const ConversationsPage({super.key, required this.userId});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Conversation> _filterConversations(List<Conversation> conversations) {
    if (_searchQuery.isEmpty) return conversations;
    final q = _searchQuery.toLowerCase();
    return conversations.where((c) {
      final name = (c.name ?? '').toLowerCase();
      final memberNames = c.members
          .map((m) => m.fullName.toLowerCase())
          .join(' ');
      final lastMsg = c.messages.isNotEmpty
          ? (c.messages.last.text ?? '').toLowerCase()
          : '';
      return name.contains(q) || memberNames.contains(q) || lastMsg.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MessagingBloc(repository: sl())
            ..add(LoadConversations(userId: widget.userId)),
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'messages.search'.tr(),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                )
              : Text('messages.title'.tr()),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
            ),
          ],
        ),
        body: BlocBuilder<MessagingBloc, MessagingState>(
          builder: (context, state) {
            if (state is MessagingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MessagingError) {
              return Center(child: Text(state.message));
            }
            if (state is ConversationsLoaded) {
              final filtered = _filterConversations(state.conversations);
              if (state.conversations.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<MessagingBloc>().add(
                      LoadConversations(userId: widget.userId),
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
              if (filtered.isEmpty && _searchQuery.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('common.no_results'.tr()),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MessagingBloc>().add(
                    LoadConversations(userId: widget.userId),
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final conv = filtered[index];
                    return _ConversationTile(
                      conversation: conv,
                      userId: widget.userId,
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
