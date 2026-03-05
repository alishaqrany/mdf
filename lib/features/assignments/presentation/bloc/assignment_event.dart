part of 'assignment_bloc.dart';

abstract class AssignmentEvent extends Equatable {
  const AssignmentEvent();
  @override
  List<Object?> get props => [];
}

class LoadAssignments extends AssignmentEvent {
  final int courseId;
  const LoadAssignments({required this.courseId});
  @override
  List<Object?> get props => [courseId];
}

class LoadSubmissions extends AssignmentEvent {
  final int assignmentId;
  const LoadSubmissions({required this.assignmentId});
  @override
  List<Object?> get props => [assignmentId];
}

class SaveAssignmentSubmission extends AssignmentEvent {
  final int assignmentId;
  final String? onlineText;
  final int? fileItemId;
  const SaveAssignmentSubmission({
    required this.assignmentId,
    this.onlineText,
    this.fileItemId,
  });
  @override
  List<Object?> get props => [assignmentId, onlineText, fileItemId];
}

class SubmitAssignment extends AssignmentEvent {
  final int assignmentId;
  const SubmitAssignment({required this.assignmentId});
  @override
  List<Object?> get props => [assignmentId];
}

class LoadGrades extends AssignmentEvent {
  final int assignmentId;
  const LoadGrades({required this.assignmentId});
  @override
  List<Object?> get props => [assignmentId];
}

class SaveGradeEvent extends AssignmentEvent {
  final int assignmentId;
  final int userId;
  final double grade;
  final String? feedback;
  const SaveGradeEvent({
    required this.assignmentId,
    required this.userId,
    required this.grade,
    this.feedback,
  });
  @override
  List<Object?> get props => [assignmentId, userId, grade, feedback];
}
