import 'package:equatable/equatable.dart';

/// A single calendar event from Moodle.
class CalendarEvent extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int? courseId;
  final String? courseName;
  final int? groupId;
  final int? userId;
  final String? moduleName;
  final int? instance;
  final String eventType; // 'site', 'course', 'group', 'user', 'category'
  final int timeStart; // unix timestamp
  final int timeDuration; // seconds
  final int? timeModified;
  final bool visible;

  const CalendarEvent({
    required this.id,
    required this.name,
    this.description,
    this.courseId,
    this.courseName,
    this.groupId,
    this.userId,
    this.moduleName,
    this.instance,
    required this.eventType,
    required this.timeStart,
    required this.timeDuration,
    this.timeModified,
    this.visible = true,
  });

  DateTime get startDateTime =>
      DateTime.fromMillisecondsSinceEpoch(timeStart * 1000);

  DateTime get endDateTime =>
      DateTime.fromMillisecondsSinceEpoch((timeStart + timeDuration) * 1000);

  bool get isAllDay => timeDuration >= 86400;

  @override
  List<Object?> get props => [id, name, eventType, timeStart];
}
