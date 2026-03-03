import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/forum.dart';
import '../bloc/forum_bloc.dart';

/// Shows discussions in a forum, with new discussion FAB and admin actions.
class DiscussionsPage extends StatelessWidget {
  final int forumId;
  final String forumName;

  const DiscussionsPage({
    super.key,
    required this.forumId,
    required this.forumName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ForumBloc(repository: sl())..add(LoadDiscussions(forumId: forumId)),
      child: Scaffold(
        appBar: AppBar(title: Text(forumName)),
        floatingActionButton: Builder(
          builder: (ctx) => FloatingActionButton(
            onPressed: () => _showNewDiscussionDialog(ctx),
            child: const Icon(Icons.add),
          ),
        ),
        body: BlocConsumer<ForumBloc, ForumState>(
          listener: (context, state) {
            if (state is ForumActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('common.success'.tr())));
            }
          },
          builder: (context, state) {
            if (state is ForumLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ForumError) {
              return Center(child: Text(state.message));
            }
            if (state is DiscussionsLoaded) {
              if (state.discussions.isEmpty) {
                return Center(child: Text('forums.no_discussions'.tr()));
              }
              // Sort: pinned first, then by timeModified desc
              final sorted = List<ForumDiscussion>.from(state.discussions)
                ..sort((a, b) {
                  if (a.pinned == true && b.pinned != true) return -1;
                  if (b.pinned == true && a.pinned != true) return 1;
                  return (b.timeModified ?? 0).compareTo(a.timeModified ?? 0);
                });
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ForumBloc>().add(
                    LoadDiscussions(forumId: forumId),
                  );
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final d = sorted[index];
                    return _DiscussionCard(discussion: d, forumId: forumId);
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

  void _showNewDiscussionDialog(BuildContext context) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('forums.new_discussion'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: InputDecoration(
                labelText: 'forums.discussions'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'messages.type_message'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ForumBloc>().add(
                AddNewDiscussion(
                  forumId: forumId,
                  subject: subjectCtrl.text,
                  message: messageCtrl.text,
                ),
              );
            },
            child: Text('common.add'.tr()),
          ),
        ],
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  final ForumDiscussion discussion;
  final int forumId;

  const _DiscussionCard({required this.discussion, required this.forumId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(
            '/forum/posts/${discussion.id}',
            extra: {'discussionName': discussion.name},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: discussion.userPictureUrl != null
                    ? CachedNetworkImageProvider(discussion.userPictureUrl!)
                    : null,
                child: discussion.userPictureUrl == null
                    ? Text(
                        discussion.userFullName?.isNotEmpty == true
                            ? discussion.userFullName![0]
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (discussion.pinned == true) ...[
                          Icon(
                            Icons.push_pin,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            discussion.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discussion.userFullName ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (discussion.numReplies != null)
                Chip(
                  label: Text('${discussion.numReplies}'),
                  avatar: const Icon(Icons.reply, size: 16),
                ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, value),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(
                      children: [
                        Icon(
                          discussion.pinned == true
                              ? Icons.push_pin_outlined
                              : Icons.push_pin,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          discussion.pinned == true
                              ? 'forums.unpin'.tr()
                              : 'forums.pin'.tr(),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'common.delete'.tr(),
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    if (action == 'pin') {
      context.read<ForumBloc>().add(
        TogglePinDiscussion(
          discussionId: discussion.id,
          forumId: forumId,
          pinned: discussion.pinned != true,
        ),
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('common.confirm'.tr()),
          content: Text('forums.confirm_delete'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.cancel'.tr()),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<ForumBloc>().add(
                  DeleteDiscussion(postId: discussion.id, forumId: forumId),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text('common.delete'.tr()),
            ),
          ],
        ),
      );
    }
  }
}

/// Shows posts in a discussion, with reply option.
class PostsPage extends StatelessWidget {
  final int discussionId;
  final String discussionName;

  const PostsPage({
    super.key,
    required this.discussionId,
    required this.discussionName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ForumBloc(repository: sl())
            ..add(LoadPosts(discussionId: discussionId)),
      child: Scaffold(
        appBar: AppBar(title: Text(discussionName)),
        body: BlocBuilder<ForumBloc, ForumState>(
          builder: (context, state) {
            if (state is ForumLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PostsLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.posts.length,
                itemBuilder: (context, index) {
                  final p = state.posts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage: p.userPictureUrl != null
                                    ? CachedNetworkImageProvider(p.userPictureUrl!)
                                    : null,
                                child: p.userPictureUrl == null
                                    ? Text(
                                        p.userFullName?.isNotEmpty == true
                                            ? p.userFullName![0]
                                            : '?',
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                p.userFullName ?? '',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (p.subject != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              p.subject!,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                          if (p.message != null) ...[
                            const SizedBox(height: 8),
                            HtmlWidget(p.message!),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _showReplyDialog(context, p.id),
                              icon: const Icon(Icons.reply, size: 18),
                              label: Text('forums.reply'.tr()),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            if (state is ForumError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showReplyDialog(BuildContext context, int postId) {
    final replyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('forums.reply'.tr()),
        content: TextField(
          controller: replyCtrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'messages.type_message'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ForumBloc>().add(
                AddReplyToPost(
                  postId: postId,
                  discussionId: discussionId,
                  subject: 'Re: $discussionName',
                  message: replyCtrl.text,
                ),
              );
            },
            child: Text('forums.post_reply'.tr()),
          ),
        ],
      ),
    );
  }
}
