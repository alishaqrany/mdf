import 'package:equatable/equatable.dart';

/// A Moodle notification.
class AppNotification extends Equatable {
  final int id;
  final int userIdFrom;
  final int userIdTo;
  final String? subject;
  final String? shortMessage;
  final String? fullMessage;
  final String? contextUrl;
  final String? contextUrlName;
  final String? component;
  final String? eventType;
  final int? timeCreated;
  final bool isRead;
  final String? userFromFullName;
  final String? userFromPictureUrl;

  const AppNotification({
    required this.id,
    required this.userIdFrom,
    required this.userIdTo,
    this.subject,
    this.shortMessage,
    this.fullMessage,
    this.contextUrl,
    this.contextUrlName,
    this.component,
    this.eventType,
    this.timeCreated,
    this.isRead = false,
    this.userFromFullName,
    this.userFromPictureUrl,
  });

  @override
  List<Object?> get props => [id];
}
