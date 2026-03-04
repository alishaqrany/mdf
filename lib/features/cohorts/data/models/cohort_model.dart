import 'package:equatable/equatable.dart';

/// Model for a cohort from the MDF plugin.
class CohortModel extends Equatable {
  final int id;
  final String name;
  final String idnumber;
  final String description;
  final int descriptionformat;
  final bool visible;
  final int membercount;
  final int timecreated;
  final int timemodified;

  const CohortModel({
    required this.id,
    required this.name,
    this.idnumber = '',
    this.description = '',
    this.descriptionformat = 0,
    this.visible = true,
    this.membercount = 0,
    this.timecreated = 0,
    this.timemodified = 0,
  });

  factory CohortModel.fromJson(Map<String, dynamic> json) {
    return CohortModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      idnumber: json['idnumber'] as String? ?? '',
      description: json['description'] as String? ?? '',
      descriptionformat: json['descriptionformat'] as int? ?? 0,
      visible: (json['visible'] as int? ?? 1) == 1,
      membercount: json['membercount'] as int? ?? 0,
      timecreated: json['timecreated'] as int? ?? 0,
      timemodified: json['timemodified'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// Model for a cohort member.
class CohortMemberModel extends Equatable {
  final int userid;
  final String fullname;
  final String email;
  final int timeadded;

  const CohortMemberModel({
    required this.userid,
    required this.fullname,
    this.email = '',
    this.timeadded = 0,
  });

  factory CohortMemberModel.fromJson(Map<String, dynamic> json) {
    return CohortMemberModel(
      userid: json['userid'] as int? ?? 0,
      fullname: json['fullname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      timeadded: json['timeadded'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [userid];
}

/// Model for a cohort-to-course sync (enrolment method).
class CohortCourseSyncModel extends Equatable {
  final int enrolid;
  final int courseid;
  final String fullname;
  final String shortname;
  final int roleid;
  final int status;

  const CohortCourseSyncModel({
    required this.enrolid,
    required this.courseid,
    required this.fullname,
    this.shortname = '',
    this.roleid = 5,
    this.status = 0,
  });

  factory CohortCourseSyncModel.fromJson(Map<String, dynamic> json) {
    return CohortCourseSyncModel(
      enrolid: json['enrolid'] as int? ?? 0,
      courseid: json['courseid'] as int? ?? 0,
      fullname: json['fullname'] as String? ?? '',
      shortname: json['shortname'] as String? ?? '',
      roleid: json['roleid'] as int? ?? 5,
      status: json['status'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [enrolid, courseid];
}
