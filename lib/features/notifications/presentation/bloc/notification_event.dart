part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final int userId;
  const LoadNotifications({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class MarkNotificationRead extends NotificationEvent {
  final int notificationId;
  final int userId;
  const MarkNotificationRead({
    required this.notificationId,
    required this.userId,
  });
  @override
  List<Object?> get props => [notificationId, userId];
}
