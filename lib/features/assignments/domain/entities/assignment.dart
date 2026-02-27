import 'package:equatable/equatable.dart';

/// Represents a Moodle assignment.
class Assignment extends Equatable {
  final int id;
  final int courseId;
  final String name;
  final String? intro;
  final int? dueDate;
  final int? allowSubmissionsFromDate;
  final int? grade;
  final bool? teamSubmission;
  final int? maxAttempts;
  final String? submissionStatus;
  final String? gradingStatus;

  const Assignment({
    required this.id,
    required this.courseId,
    required this.name,
    this.intro,
    this.dueDate,
    this.allowSubmissionsFromDate,
    this.grade,
    this.teamSubmission,
    this.maxAttempts,
    this.submissionStatus,
    this.gradingStatus,
  });

  bool get isOverdue =>
      dueDate != null &&
      DateTime.fromMillisecondsSinceEpoch(
        dueDate! * 1000,
      ).isBefore(DateTime.now());

  @override
  List<Object?> get props => [id, courseId, name];
}

/// An assignment submission.
class AssignmentSubmission extends Equatable {
  final int id;
  final int userId;
  final int assignmentId;
  final String status; // new, draft, submitted
  final int? timeCreated;
  final int? timeModified;

  const AssignmentSubmission({
    required this.id,
    required this.userId,
    required this.assignmentId,
    required this.status,
    this.timeCreated,
    this.timeModified,
  });

  bool get isSubmitted => status == 'submitted';

  @override
  List<Object?> get props => [id, assignmentId, status];
}

/// Grade for an assignment.
class AssignmentGrade extends Equatable {
  final int id;
  final int userId;
  final int assignmentId;
  final double? grade;
  final String? grader;
  final int? timeCreated;
  final int? timeModified;

  const AssignmentGrade({
    required this.id,
    required this.userId,
    required this.assignmentId,
    this.grade,
    this.grader,
    this.timeCreated,
    this.timeModified,
  });

  @override
  List<Object?> get props => [id, assignmentId];
}
