import 'package:equatable/equatable.dart';

/// Represents a Moodle course.
class Course extends Equatable {
  final int id;
  final String shortName;
  final String fullName;
  final String? displayName;
  final String? summary;
  final int? summaryFormat;
  final int? categoryId;
  final String? categoryName;
  final int? startDate;
  final int? endDate;
  final String? imageUrl;
  final int? enrolledUserCount;
  final bool? visible;
  final double? progress;
  final bool? completed;
  final bool? isFavourite;
  final int? lastAccess;

  const Course({
    required this.id,
    required this.shortName,
    required this.fullName,
    this.displayName,
    this.summary,
    this.summaryFormat,
    this.categoryId,
    this.categoryName,
    this.startDate,
    this.endDate,
    this.imageUrl,
    this.enrolledUserCount,
    this.visible,
    this.progress,
    this.completed,
    this.isFavourite,
    this.lastAccess,
  });

  @override
  List<Object?> get props => [id, shortName, fullName];
}

/// Represents a course category.
class CourseCategory extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int? parent;
  final int courseCount;
  final int depth;

  const CourseCategory({
    required this.id,
    required this.name,
    this.description,
    this.parent,
    this.courseCount = 0,
    this.depth = 0,
  });

  @override
  List<Object?> get props => [id, name];
}
