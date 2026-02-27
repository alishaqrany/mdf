import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../bloc/notification_bloc.dart';

/// Notifications list page.
class NotificationsPage extends StatelessWidget {
  final int userId;

  const NotificationsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          NotificationBloc(repository: sl())
            ..add(LoadNotifications(userId: userId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('notifications.title'.tr()),
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) {
                if (state is NotificationsLoaded &&
                    state.notifications.any((n) => !n.isRead)) {
                  return TextButton(
                    onPressed: () {
                      // Mark all as read
                      for (final n in state.notifications.where(
                        (n) => !n.isRead,
                      )) {
                        context.read<NotificationBloc>().add(
                          MarkNotificationRead(
                            notificationId: n.id,
                            userId: userId,
                          ),
                        );
                      }
                    },
                    child: Text('notifications.mark_all_read'.tr()),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationError) {
              return Center(child: Text(state.message));
            }
            if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text('notifications.no_notifications'.tr()),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final n = state.notifications[index];
                  final time = n.timeCreated != null
                      ? DateTime.fromMillisecondsSinceEpoch(
                          n.timeCreated! * 1000,
                        )
                      : null;

                  return ListTile(
                    tileColor: n.isRead
                        ? null
                        : Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    leading: CircleAvatar(
                      child: Icon(_iconForComponent(n.component), size: 20),
                    ),
                    title: Text(
                      n.subject ?? '',
                      style: n.isRead
                          ? null
                          : const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.shortMessage != null)
                          Text(
                            n.shortMessage!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (time != null)
                          Text(
                            '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    trailing: !n.isRead
                        ? IconButton(
                            icon: const Icon(Icons.mark_email_read, size: 20),
                            onPressed: () {
                              context.read<NotificationBloc>().add(
                                MarkNotificationRead(
                                  notificationId: n.id,
                                  userId: userId,
                                ),
                              );
                            },
                          )
                        : null,
                    isThreeLine: true,
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

  IconData _iconForComponent(String? component) {
    switch (component) {
      case 'mod_assign':
        return Icons.assignment;
      case 'mod_quiz':
        return Icons.quiz;
      case 'mod_forum':
        return Icons.forum;
      case 'core':
        return Icons.settings;
      default:
        return Icons.notifications;
    }
  }
}
