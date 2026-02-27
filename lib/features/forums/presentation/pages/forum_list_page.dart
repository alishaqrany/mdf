import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../bloc/forum_bloc.dart';

/// Lists forums in a course. Tapping a forum shows its discussions.
class ForumListPage extends StatelessWidget {
  final int courseId;

  const ForumListPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ForumBloc(repository: sl())..add(LoadForums(courseId: courseId)),
      child: Scaffold(
        appBar: AppBar(title: Text('forums.title'.tr())),
        body: BlocBuilder<ForumBloc, ForumState>(
          builder: (context, state) {
            if (state is ForumLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ForumError) {
              return Center(child: Text(state.message));
            }
            if (state is ForumsLoaded) {
              if (state.forums.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.forum_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text('forums.no_discussions'.tr()),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.forums.length,
                itemBuilder: (context, index) {
                  final forum = state.forums[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(
                        Icons.forum_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(forum.name),
                      subtitle: forum.type != null ? Text(forum.type!) : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.push(
                          '/forum/discussions/${forum.id}',
                          extra: {'forumName': forum.name},
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
}
