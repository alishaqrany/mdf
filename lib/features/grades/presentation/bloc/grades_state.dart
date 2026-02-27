part of 'grades_bloc.dart';

abstract class GradesState extends Equatable {
  const GradesState();
  @override
  List<Object?> get props => [];
}

class GradesInitial extends GradesState {}

class GradesLoading extends GradesState {}

class GradeItemsLoaded extends GradesState {
  final List<GradeItem> items;
  const GradeItemsLoaded({required this.items});
  @override
  List<Object?> get props => [items];
}

class CourseGradesLoaded extends GradesState {
  final List<CourseGrade> grades;
  const CourseGradesLoaded({required this.grades});
  @override
  List<Object?> get props => [grades];
}

class GradesError extends GradesState {
  final String message;
  const GradesError({required this.message});
  @override
  List<Object?> get props => [message];
}
