part of 'courses_bloc.dart';

abstract class CoursesEvent extends Equatable {
  const CoursesEvent();
  @override
  List<Object?> get props => [];
}

class LoadEnrolledCourses extends CoursesEvent {
  final int userId;
  const LoadEnrolledCourses({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class SearchCoursesEvent extends CoursesEvent {
  final String query;
  const SearchCoursesEvent({required this.query});
  @override
  List<Object?> get props => [query];
}

class RefreshCourses extends CoursesEvent {
  final int userId;
  const RefreshCourses({required this.userId});
  @override
  List<Object?> get props => [userId];
}
