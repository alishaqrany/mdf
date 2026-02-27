import '../../domain/entities/grade.dart';

class GradeItemModel extends GradeItem {
  const GradeItemModel({
    required super.id,
    required super.itemName,
    super.itemType,
    super.itemModule,
    super.courseId,
    super.gradeRaw,
    super.gradeMin,
    super.gradeMax,
    super.gradeDateSubmitted,
    super.gradeDateGraded,
    super.percentageFormatted,
    super.feedback,
  });

  factory GradeItemModel.fromJson(Map<String, dynamic> json) {
    return GradeItemModel(
      id: json['id'] as int? ?? 0,
      itemName: json['itemname'] as String? ?? '',
      itemType: json['itemtype'] as String?,
      itemModule: json['itemmodule'] as String?,
      courseId: json['courseid'] as int?,
      gradeRaw: (json['graderaw'] as num?)?.toDouble(),
      gradeMin: (json['grademin'] as num?)?.toDouble(),
      gradeMax: (json['grademax'] as num?)?.toDouble(),
      gradeDateSubmitted: json['gradedatesubmitted'] as String?,
      gradeDateGraded: json['gradedategraded'] as String?,
      percentageFormatted: (json['percentageformatted'] as num?)?.toDouble(),
      feedback: json['feedback'] as String?,
    );
  }
}

class CourseGradeModel extends CourseGrade {
  const CourseGradeModel({
    required super.courseId,
    required super.courseName,
    super.grade,
    super.rank,
  });

  factory CourseGradeModel.fromJson(Map<String, dynamic> json) {
    return CourseGradeModel(
      courseId: json['courseid'] as int? ?? 0,
      courseName:
          json['coursename'] as String? ?? json['fullname'] as String? ?? '',
      grade: (json['grade'] as num?)?.toDouble(),
      rank: json['rank'] as int?,
    );
  }
}
