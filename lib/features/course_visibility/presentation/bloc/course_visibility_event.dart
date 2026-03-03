part of 'course_visibility_bloc.dart';

abstract class CourseVisibilityEvent extends Equatable {
  const CourseVisibilityEvent();

  @override
  List<Object?> get props => [];
}

class LoadCourseVisibility extends CourseVisibilityEvent {
  final int courseid;
  const LoadCourseVisibility({this.courseid = 0});

  @override
  List<Object?> get props => [courseid];
}

class SetCourseVisibilityEvent extends CourseVisibilityEvent {
  final int courseid;
  final String targettype;
  final int targetid;
  final int hidden;

  const SetCourseVisibilityEvent({
    required this.courseid,
    required this.targettype,
    this.targetid = 0,
    required this.hidden,
  });

  @override
  List<Object?> get props => [courseid, targettype, targetid, hidden];
}

class RemoveCourseVisibilityEvent extends CourseVisibilityEvent {
  final int id;
  const RemoveCourseVisibilityEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
