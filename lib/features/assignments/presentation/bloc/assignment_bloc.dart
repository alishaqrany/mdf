import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/assignment.dart';
import '../../domain/repositories/assignment_repository.dart';

part 'assignment_event.dart';
part 'assignment_state.dart';

class AssignmentBloc extends Bloc<AssignmentEvent, AssignmentState> {
  final AssignmentRepository repository;

  AssignmentBloc({required this.repository}) : super(AssignmentInitial()) {
    on<LoadAssignments>(_onLoadAssignments);
    on<LoadSubmissions>(_onLoadSubmissions);
    on<SubmitAssignment>(_onSubmitAssignment);
    on<SaveAssignmentSubmission>(_onSaveSubmission);
  }

  Future<void> _onLoadAssignments(
    LoadAssignments event,
    Emitter<AssignmentState> emit,
  ) async {
    emit(AssignmentLoading());
    final result = await repository.getAssignmentsByCourse(event.courseId);
    result.fold(
      (f) => emit(AssignmentError(message: f.message)),
      (assignments) => emit(AssignmentsLoaded(assignments: assignments)),
    );
  }

  Future<void> _onLoadSubmissions(
    LoadSubmissions event,
    Emitter<AssignmentState> emit,
  ) async {
    emit(AssignmentLoading());
    final result = await repository.getSubmissions(event.assignmentId);
    result.fold(
      (f) => emit(AssignmentError(message: f.message)),
      (submissions) => emit(SubmissionsLoaded(submissions: submissions)),
    );
  }

  Future<void> _onSaveSubmission(
    SaveAssignmentSubmission event,
    Emitter<AssignmentState> emit,
  ) async {
    emit(AssignmentLoading());
    final result = await repository.saveSubmission(
      event.assignmentId,
      event.onlineText,
      event.fileItemId,
    );
    result.fold(
      (f) => emit(AssignmentError(message: f.message)),
      (_) => emit(AssignmentSubmitted()),
    );
  }

  Future<void> _onSubmitAssignment(
    SubmitAssignment event,
    Emitter<AssignmentState> emit,
  ) async {
    emit(AssignmentLoading());
    final result = await repository.submitForGrading(event.assignmentId);
    result.fold(
      (f) => emit(AssignmentError(message: f.message)),
      (_) => emit(AssignmentSubmitted()),
    );
  }
}
