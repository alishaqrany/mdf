part of 'course_content_bloc.dart';

abstract class CourseContentEvent extends Equatable {
  const CourseContentEvent();
  @override
  List<Object?> get props => [];
}

class LoadCourseContent extends CourseContentEvent {
  final int courseId;
  const LoadCourseContent({required this.courseId});
  @override
  List<Object?> get props => [courseId];
}

class ToggleActivityCompletion extends CourseContentEvent {
  final int cmId;
  final int courseId;
  final bool completed;
  const ToggleActivityCompletion({
    required this.cmId,
    required this.courseId,
    required this.completed,
  });
  @override
  List<Object?> get props => [cmId, courseId, completed];
}
