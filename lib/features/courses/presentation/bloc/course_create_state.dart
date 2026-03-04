part of 'course_create_bloc.dart';

abstract class CourseCreateState extends Equatable {
  const CourseCreateState();
  @override
  List<Object?> get props => [];
}

class CourseCreateInitial extends CourseCreateState {}

class CourseCreateLoading extends CourseCreateState {}

class CategoriesLoadedForCreate extends CourseCreateState {
  final List<CourseCategoryModel> categories;
  const CategoriesLoadedForCreate({required this.categories});
  @override
  List<Object?> get props => [categories];
}

class CourseCreateSubmitting extends CourseCreateState {}

class CourseCreateSuccess extends CourseCreateState {
  final int? courseId;
  final String courseName;
  const CourseCreateSuccess({this.courseId, required this.courseName});
  @override
  List<Object?> get props => [courseId, courseName];
}

class CourseCreateError extends CourseCreateState {
  final String message;
  const CourseCreateError({required this.message});
  @override
  List<Object?> get props => [message];
}
