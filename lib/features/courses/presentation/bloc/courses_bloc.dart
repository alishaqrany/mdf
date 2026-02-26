import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/course.dart';
import '../../domain/usecases/get_enrolled_courses_usecase.dart';
import '../../domain/usecases/search_courses_usecase.dart';

part 'courses_event.dart';
part 'courses_state.dart';

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final GetEnrolledCoursesUseCase getEnrolledCourses;
  final SearchCoursesUseCase searchCourses;

  CoursesBloc({required this.getEnrolledCourses, required this.searchCourses})
    : super(CoursesInitial()) {
    on<LoadEnrolledCourses>(_onLoadEnrolledCourses);
    on<SearchCoursesEvent>(_onSearchCourses);
    on<RefreshCourses>(_onRefreshCourses);
  }

  Future<void> _onLoadEnrolledCourses(
    LoadEnrolledCourses event,
    Emitter<CoursesState> emit,
  ) async {
    emit(CoursesLoading());

    final result = await getEnrolledCourses(event.userId);

    result.fold(
      (failure) => emit(CoursesError(message: failure.message)),
      (courses) => emit(CoursesLoaded(courses: courses)),
    );
  }

  Future<void> _onSearchCourses(
    SearchCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    emit(CoursesLoading());

    final result = await searchCourses(event.query);

    result.fold(
      (failure) => emit(CoursesError(message: failure.message)),
      (courses) =>
          emit(CoursesSearchResults(courses: courses, query: event.query)),
    );
  }

  Future<void> _onRefreshCourses(
    RefreshCourses event,
    Emitter<CoursesState> emit,
  ) async {
    final result = await getEnrolledCourses(event.userId);

    result.fold(
      (failure) => emit(CoursesError(message: failure.message)),
      (courses) => emit(CoursesLoaded(courses: courses)),
    );
  }
}
