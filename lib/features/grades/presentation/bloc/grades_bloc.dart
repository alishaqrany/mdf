import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/grade.dart';
import '../../domain/repositories/grade_repository.dart';

part 'grades_event.dart';
part 'grades_state.dart';

class GradesBloc extends Bloc<GradesEvent, GradesState> {
  final GradeRepository repository;

  GradesBloc({required this.repository}) : super(GradesInitial()) {
    on<LoadCourseGradeItems>(_onLoadGradeItems);
    on<LoadAllCourseGrades>(_onLoadCourseGrades);
  }

  Future<void> _onLoadGradeItems(
    LoadCourseGradeItems event,
    Emitter<GradesState> emit,
  ) async {
    emit(GradesLoading());
    final result = await repository.getGradeItems(event.courseId, event.userId);
    result.fold(
      (f) => emit(GradesError(message: f.message)),
      (items) => emit(GradeItemsLoaded(items: items)),
    );
  }

  Future<void> _onLoadCourseGrades(
    LoadAllCourseGrades event,
    Emitter<GradesState> emit,
  ) async {
    emit(GradesLoading());
    final result = await repository.getCourseGrades(event.userId);
    result.fold(
      (f) => emit(GradesError(message: f.message)),
      (grades) => emit(CourseGradesLoaded(grades: grades)),
    );
  }
}
