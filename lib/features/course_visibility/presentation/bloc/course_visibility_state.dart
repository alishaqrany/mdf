part of 'course_visibility_bloc.dart';

abstract class CourseVisibilityState extends Equatable {
  const CourseVisibilityState();

  @override
  List<Object?> get props => [];
}

class CourseVisibilityInitial extends CourseVisibilityState {}

class CourseVisibilityLoading extends CourseVisibilityState {}

class CourseVisibilityLoaded extends CourseVisibilityState {
  final List<CourseVisibilityOverride> overrides;

  const CourseVisibilityLoaded({required this.overrides});

  @override
  List<Object?> get props => [overrides];
}

class CourseVisibilityError extends CourseVisibilityState {
  final String message;
  const CourseVisibilityError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CourseVisibilityActionSuccess extends CourseVisibilityState {
  final String message;
  const CourseVisibilityActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
