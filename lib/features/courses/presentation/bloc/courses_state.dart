part of 'courses_bloc.dart';

abstract class CoursesState extends Equatable {
  const CoursesState();
  @override
  List<Object?> get props => [];
}

class CoursesInitial extends CoursesState {}

class CoursesLoading extends CoursesState {}

class CoursesLoaded extends CoursesState {
  final List<Course> courses;
  const CoursesLoaded({required this.courses});
  @override
  List<Object?> get props => [courses];
}

class CoursesSearchResults extends CoursesState {
  final List<Course> courses;
  final String query;
  const CoursesSearchResults({required this.courses, required this.query});
  @override
  List<Object?> get props => [courses, query];
}

class CoursesError extends CoursesState {
  final String message;
  const CoursesError({required this.message});
  @override
  List<Object?> get props => [message];
}
