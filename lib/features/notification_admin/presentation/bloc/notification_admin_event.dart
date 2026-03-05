import 'package:equatable/equatable.dart';

abstract class NotificationAdminEvent extends Equatable {
  const NotificationAdminEvent();

  @override
  List<Object?> get props => [];
}

class LoadUsers extends NotificationAdminEvent {
  final String? search;
  final int? courseId;
  final int? cohortId;

  const LoadUsers({this.search, this.courseId, this.cohortId});

  @override
  List<Object?> get props => [search, courseId, cohortId];
}

class SendNotifications extends NotificationAdminEvent {
  final List<int> userIds;
  final String subject;
  final String message;
  final bool sendFcm;

  const SendNotifications({
    required this.userIds,
    required this.subject,
    required this.message,
    this.sendFcm = true,
  });

  @override
  List<Object?> get props => [userIds, subject, message, sendFcm];
}

class LoadNotificationLog extends NotificationAdminEvent {
  final int page;
  final String? status;

  const LoadNotificationLog({this.page = 0, this.status});

  @override
  List<Object?> get props => [page, status];
}
