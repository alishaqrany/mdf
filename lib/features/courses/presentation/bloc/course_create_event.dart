part of 'course_create_bloc.dart';

abstract class CourseCreateEvent extends Equatable {
  const CourseCreateEvent();
  @override
  List<Object?> get props => [];
}

class LoadCategoriesForCreate extends CourseCreateEvent {}

class SubmitCourseCreate extends CourseCreateEvent {
  final String fullName;
  final String shortName;
  final int categoryId;
  final String? summary;
  final bool? visible;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? format;
  final int? numSections;

  const SubmitCourseCreate({
    required this.fullName,
    required this.shortName,
    required this.categoryId,
    this.summary,
    this.visible,
    this.startDate,
    this.endDate,
    this.format,
    this.numSections,
  });

  @override
  List<Object?> get props => [
        fullName,
        shortName,
        categoryId,
        summary,
        visible,
        startDate,
        endDate,
        format,
        numSections,
      ];
}
