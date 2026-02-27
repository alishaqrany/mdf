part of 'grades_bloc.dart';

abstract class GradesEvent extends Equatable {
  const GradesEvent();
  @override
  List<Object?> get props => [];
}

class LoadCourseGradeItems extends GradesEvent {
  final int courseId;
  final int userId;
  const LoadCourseGradeItems({required this.courseId, required this.userId});
  @override
  List<Object?> get props => [courseId, userId];
}

class LoadAllCourseGrades extends GradesEvent {
  final int userId;
  const LoadAllCourseGrades({required this.userId});
  @override
  List<Object?> get props => [userId];
}
