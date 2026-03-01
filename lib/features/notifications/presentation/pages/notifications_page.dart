import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../app/di/injection.dart';
import '../../domain/entities/notification.dart' as n;
import '../bloc/notification_bloc.dart';

/// Notifications list page with navigation and improved UI.
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
                  return TextButton.icon(
                    onPressed: () {
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
                    icon: const Icon(Icons.done_all, size: 18),
                    label: Text('notifications.mark_all_read'.tr()),
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
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 8),
                    Text(state.message),
                  ],
                ),
              );
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
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<NotificationBloc>().add(
                    LoadNotifications(userId: userId),
                  );
                },
                child: ListView.separated(
                  itemCount: state.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notification = state.notifications[index];
                    return _NotificationTile(
                      notification: notification,
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

class _NotificationTile extends StatelessWidget {
  final n.AppNotification notification;
  final int userId;

  const _NotificationTile({required this.notification, required this.userId});

  @override
  Widget build(BuildContext context) {
    final color = _colorForComponent(notification.component);
    final timeText = _formatTime(notification.timeCreated);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: notification.isRead
          ? DismissDirection.none
          : DismissDirection.startToEnd,
      background: Container(
        color: Colors.green.shade100,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 16),
        child: const Icon(Icons.mark_email_read, color: Colors.green),
      ),
      onDismissed: (_) {
        context.read<NotificationBloc>().add(
          MarkNotificationRead(notificationId: notification.id, userId: userId),
        );
      },
      child: InkWell(
        onTap: () => _navigateToContext(context),
        child: Container(
          color: notification.isRead
              ? null
              : Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.15),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon with color indicator
              Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Icon(
                      _iconForComponent(notification.component),
                      size: 20,
                      color: color,
                    ),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.subject ?? '',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeText != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            timeText,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                    if (notification.shortMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.shortMessage!.replaceAll(
                          RegExp(r'<[^>]*>'),
                          '',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (notification.userFromFullName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            notification.userFromFullName!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Mark-read button
              if (!notification.isRead)
                IconButton(
                  icon: const Icon(Icons.mark_email_read, size: 18),
                  tooltip: 'notifications.mark_read'.tr(),
                  onPressed: () {
                    context.read<NotificationBloc>().add(
                      MarkNotificationRead(
                        notificationId: notification.id,
                        userId: userId,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToContext(BuildContext context) {
    // First mark as read if unread
    if (!notification.isRead) {
      context.read<NotificationBloc>().add(
        MarkNotificationRead(notificationId: notification.id, userId: userId),
      );
    }

    // Navigate based on component type
    final url = notification.contextUrl;
    if (url == null || url.isEmpty) return;

    switch (notification.component) {
      case 'mod_assign':
        // Extract assignment id from contextUrl if possible
        final match = RegExp(r'id=(\d+)').firstMatch(url);
        if (match != null) {
          context.push('/assignment/detail/${match.group(1)}');
        }
        break;
      case 'mod_quiz':
        final match = RegExp(r'id=(\d+)').firstMatch(url);
        if (match != null) {
          context.push(
            '/quiz/info',
            extra: {'quizId': int.tryParse(match.group(1)!)},
          );
        }
        break;
      case 'mod_forum':
        final match = RegExp(r'd=(\d+)').firstMatch(url);
        if (match != null) {
          context.push('/forum/posts/${match.group(1)}');
        }
        break;
      default:
        // Show full notification content in a bottom sheet
        _showFullContent(context);
        break;
    }
  }

  void _showFullContent(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                notification.subject ?? '',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (notification.userFromFullName != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 16),
                    const SizedBox(width: 4),
                    Text(notification.userFromFullName!),
                  ],
                ),
              const SizedBox(height: 16),
              Text(
                (notification.fullMessage ?? notification.shortMessage ?? '')
                    .replaceAll(RegExp(r'<[^>]*>'), ''),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatTime(int? timestamp) {
    if (timestamp == null) return null;
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return timeago.format(date);
    } catch (_) {
      return null;
    }
  }

  Color _colorForComponent(String? component) {
    switch (component) {
      case 'mod_assign':
        return Colors.orange;
      case 'mod_quiz':
        return Colors.blue;
      case 'mod_forum':
        return Colors.green;
      case 'core':
        return Colors.purple;
      case 'mod_chat':
        return Colors.teal;
      default:
        return Colors.grey;
    }
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
      case 'mod_chat':
        return Icons.chat;
      default:
        return Icons.notifications;
    }
  }
}
