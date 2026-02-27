import 'package:equatable/equatable.dart';

/// A grade table item from Moodle gradebook.
class GradeItem extends Equatable {
  final int id;
  final String itemName;
  final String? itemType;
  final String? itemModule;
  final int? courseId;
  final double? gradeRaw;
  final double? gradeMin;
  final double? gradeMax;
  final String? gradeDateSubmitted;
  final String? gradeDateGraded;
  final double? percentageFormatted;
  final String? feedback;

  const GradeItem({
    required this.id,
    required this.itemName,
    this.itemType,
    this.itemModule,
    this.courseId,
    this.gradeRaw,
    this.gradeMin,
    this.gradeMax,
    this.gradeDateSubmitted,
    this.gradeDateGraded,
    this.percentageFormatted,
    this.feedback,
  });

  @override
  List<Object?> get props => [id, itemName];
}

/// A course with its overall grade.
class CourseGrade extends Equatable {
  final int courseId;
  final String courseName;
  final double? grade;
  final int? rank;

  const CourseGrade({
    required this.courseId,
    required this.courseName,
    this.grade,
    this.rank,
  });

  @override
  List<Object?> get props => [courseId];
}
