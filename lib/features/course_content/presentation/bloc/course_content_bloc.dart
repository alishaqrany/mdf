import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/course_content.dart';
import '../../domain/repositories/course_content_repository.dart';

part 'course_content_event.dart';
part 'course_content_state.dart';

class CourseContentBloc extends Bloc<CourseContentEvent, CourseContentState> {
  final CourseContentRepository repository;

  CourseContentBloc({required this.repository})
    : super(CourseContentInitial()) {
    on<LoadCourseContent>(_onLoadContent);
    on<ToggleActivityCompletion>(_onToggleCompletion);
  }

  Future<void> _onLoadContent(
    LoadCourseContent event,
    Emitter<CourseContentState> emit,
  ) async {
    emit(CourseContentLoading());

    final result = await repository.getCourseContents(event.courseId);

    result.fold(
      (failure) => emit(CourseContentError(message: failure.message)),
      (sections) => emit(CourseContentLoaded(sections: sections)),
    );
  }

  Future<void> _onToggleCompletion(
    ToggleActivityCompletion event,
    Emitter<CourseContentState> emit,
  ) async {
    await repository.updateActivityCompletion(event.cmId, event.completed);
    // Reload content to reflect changes
    add(LoadCourseContent(courseId: event.courseId));
  }
}
