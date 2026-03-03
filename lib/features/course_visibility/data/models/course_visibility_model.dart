import 'package:equatable/equatable.dart';

/// Represents a course visibility override from the MDF plugin.
class CourseVisibilityOverride extends Equatable {
  final int id;
  final int courseid;
  final String coursename;
  final String targettype; // 'all', 'user', 'cohort'
  final int targetid;
  final String targetname;
  final bool hidden;
  final int timecreated;
  final int timemodified;

  const CourseVisibilityOverride({
    required this.id,
    required this.courseid,
    required this.coursename,
    required this.targettype,
    required this.targetid,
    required this.targetname,
    required this.hidden,
    required this.timecreated,
    required this.timemodified,
  });

  factory CourseVisibilityOverride.fromJson(Map<String, dynamic> json) {
    return CourseVisibilityOverride(
      id: json['id'] as int? ?? 0,
      courseid: json['courseid'] as int? ?? 0,
      coursename: json['coursename'] as String? ?? '',
      targettype: json['targettype'] as String? ?? 'all',
      targetid: json['targetid'] as int? ?? 0,
      targetname: json['targetname'] as String? ?? '',
      hidden: (json['hidden'] as int? ?? 1) == 1,
      timecreated: json['timecreated'] as int? ?? 0,
      timemodified: json['timemodified'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseid': courseid,
    'coursename': coursename,
    'targettype': targettype,
    'targetid': targetid,
    'targetname': targetname,
    'hidden': hidden ? 1 : 0,
    'timecreated': timecreated,
    'timemodified': timemodified,
  };

  @override
  List<Object?> get props => [id, courseid, targettype, targetid, hidden];
}
