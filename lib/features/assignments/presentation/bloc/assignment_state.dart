part of 'assignment_bloc.dart';

abstract class AssignmentState extends Equatable {
  const AssignmentState();
  @override
  List<Object?> get props => [];
}

class AssignmentInitial extends AssignmentState {}

class AssignmentLoading extends AssignmentState {}

class AssignmentsLoaded extends AssignmentState {
  final List<Assignment> assignments;
  const AssignmentsLoaded({required this.assignments});
  @override
  List<Object?> get props => [assignments];
}

class SubmissionsLoaded extends AssignmentState {
  final List<AssignmentSubmission> submissions;
  const SubmissionsLoaded({required this.submissions});
  @override
  List<Object?> get props => [submissions];
}

class AssignmentSubmitted extends AssignmentState {}

class AssignmentGradesLoaded extends AssignmentState {
  final List<AssignmentGrade> grades;
  const AssignmentGradesLoaded({required this.grades});
  @override
  List<Object?> get props => [grades];
}

class AssignmentError extends AssignmentState {
  final String message;
  const AssignmentError({required this.message});
  @override
  List<Object?> get props => [message];
}
