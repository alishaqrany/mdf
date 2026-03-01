import '../../domain/entities/notification.dart';

class AppNotificationModel extends AppNotification {
  const AppNotificationModel({
    required super.id,
    required super.userIdFrom,
    required super.userIdTo,
    super.subject,
    super.shortMessage,
    super.fullMessage,
    super.contextUrl,
    super.contextUrlName,
    super.component,
    super.eventType,
    super.timeCreated,
    super.isRead,
    super.userFromFullName,
    super.userFromPictureUrl,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    return AppNotificationModel(
      id: json['id'] as int,
      userIdFrom: json['useridfrom'] as int? ?? 0,
      userIdTo: json['useridto'] as int? ?? 0,
      subject: json['subject'] as String?,
      shortMessage:
          json['shortenedsubject'] as String? ??
          json['smallmessage'] as String?,
      fullMessage: json['fullmessage'] as String?,
      contextUrl: json['contexturl'] as String?,
      contextUrlName: json['contexturlname'] as String?,
      component: json['component'] as String?,
      eventType: json['eventtype'] as String?,
      timeCreated: json['timecreated'] as int?,
      isRead: json['read'] == true || json['timeread'] != null,
      userFromFullName: json['userfromfullname'] as String?,
      userFromPictureUrl: json['userfromprofileurl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'useridfrom': userIdFrom,
    'useridto': userIdTo,
    'subject': subject,
    'smallmessage': shortMessage,
    'fullmessage': fullMessage,
    'contexturl': contextUrl,
    'contexturlname': contextUrlName,
    'component': component,
    'eventtype': eventType,
    'timecreated': timeCreated,
    'read': isRead,
    'userfromfullname': userFromFullName,
    'userfromprofileurl': userFromPictureUrl,
  };
}
