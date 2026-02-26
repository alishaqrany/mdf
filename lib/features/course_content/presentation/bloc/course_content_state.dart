part of 'course_content_bloc.dart';

abstract class CourseContentState extends Equatable {
  const CourseContentState();
  @override
  List<Object?> get props => [];
}

class CourseContentInitial extends CourseContentState {}

class CourseContentLoading extends CourseContentState {}

class CourseContentLoaded extends CourseContentState {
  final List<CourseSection> sections;
  const CourseContentLoaded({required this.sections});
  @override
  List<Object?> get props => [sections];
}

class CourseContentError extends CourseContentState {
  final String message;
  const CourseContentError({required this.message});
  @override
  List<Object?> get props => [message];
}
