import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../bloc/forum_bloc.dart';

/// Shows discussions in a forum, with new discussion FAB.
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
        body: BlocBuilder<ForumBloc, ForumState>(
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
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.discussions.length,
                itemBuilder: (context, index) {
                  final d = state.discussions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: d.userPictureUrl != null
                            ? NetworkImage(d.userPictureUrl!)
                            : null,
                        child: d.userPictureUrl == null
                            ? Text(
                                d.userFullName?.isNotEmpty == true
                                    ? d.userFullName![0]
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(d.name),
                      subtitle: Text(d.userFullName ?? ''),
                      trailing: d.numReplies != null
                          ? Chip(
                              label: Text('${d.numReplies}'),
                              avatar: const Icon(Icons.reply, size: 16),
                            )
                          : null,
                      onTap: () {
                        context.push(
                          '/forum/posts/${d.id}',
                          extra: {'discussionName': d.name},
                        );
                      },
                    ),
                  );
                },
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
                                    ? NetworkImage(p.userPictureUrl!)
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
