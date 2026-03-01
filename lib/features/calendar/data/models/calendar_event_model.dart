import '../../domain/entities/calendar_event.dart';

class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.name,
    super.description,
    super.courseId,
    super.courseName,
    super.groupId,
    super.userId,
    super.moduleName,
    super.instance,
    required super.eventType,
    required super.timeStart,
    required super.timeDuration,
    super.timeModified,
    super.visible,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      courseId: json['courseid'] as int?,
      courseName: json['coursename'] as String?,
      groupId: json['groupid'] as int?,
      userId: json['userid'] as int?,
      moduleName: json['modulename'] as String?,
      instance: json['instance'] as int?,
      eventType: json['eventtype'] as String? ?? 'site',
      timeStart: json['timestart'] as int? ?? 0,
      timeDuration: json['timeduration'] as int? ?? 0,
      timeModified: json['timemodified'] as int?,
      visible: (json['visible'] as int?) != 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'courseid': courseId,
    'coursename': courseName,
    'groupid': groupId,
    'userid': userId,
    'modulename': moduleName,
    'instance': instance,
    'eventtype': eventType,
    'timestart': timeStart,
    'timeduration': timeDuration,
    'timemodified': timeModified,
    'visible': visible ? 1 : 0,
  };
}
