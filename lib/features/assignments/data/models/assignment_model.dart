import '../../domain/entities/assignment.dart';

class AssignmentModel extends Assignment {
  const AssignmentModel({
    required super.id,
    required super.courseId,
    required super.name,
    super.intro,
    super.dueDate,
    super.allowSubmissionsFromDate,
    super.grade,
    super.teamSubmission,
    super.maxAttempts,
    super.submissionStatus,
    super.gradingStatus,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as int,
      courseId: json['course'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      intro: json['intro'] as String?,
      dueDate: json['duedate'] as int?,
      allowSubmissionsFromDate: json['allowsubmissionsfromdate'] as int?,
      grade: json['grade'] as int?,
      teamSubmission: json['teamsubmission'] == 1,
      maxAttempts: json['maxattempts'] as int?,
    );
  }
}

class AssignmentSubmissionModel extends AssignmentSubmission {
  const AssignmentSubmissionModel({
    required super.id,
    required super.userId,
    required super.assignmentId,
    required super.status,
    super.timeCreated,
    super.timeModified,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      assignmentId: json['assignment'] as int? ?? 0,
      status: json['status'] as String? ?? 'new',
      timeCreated: json['timecreated'] as int?,
      timeModified: json['timemodified'] as int?,
    );
  }
}

class AssignmentGradeModel extends AssignmentGrade {
  const AssignmentGradeModel({
    required super.id,
    required super.userId,
    required super.assignmentId,
    super.grade,
    super.grader,
    super.timeCreated,
    super.timeModified,
  });

  factory AssignmentGradeModel.fromJson(Map<String, dynamic> json) {
    return AssignmentGradeModel(
      id: json['id'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      assignmentId: json['assignment'] as int? ?? 0,
      grade: (json['grade'] as num?)?.toDouble(),
      grader: json['grader']?.toString(),
      timeCreated: json['timecreated'] as int?,
      timeModified: json['timemodified'] as int?,
    );
  }
}
