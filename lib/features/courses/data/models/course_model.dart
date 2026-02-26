import '../../domain/entities/course.dart';

/// Course model with JSON serialization.
class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.shortName,
    required super.fullName,
    super.displayName,
    super.summary,
    super.summaryFormat,
    super.categoryId,
    super.categoryName,
    super.startDate,
    super.endDate,
    super.imageUrl,
    super.enrolledUserCount,
    super.visible,
    super.progress,
    super.completed,
    super.isFavourite,
    super.lastAccess,
  });

  /// Create from Moodle enrolled course response.
  factory CourseModel.fromEnrolledCourse(Map<String, dynamic> json) {
    // Extract course image from overviewfiles
    String? imageUrl;
    if (json['overviewfiles'] is List &&
        (json['overviewfiles'] as List).isNotEmpty) {
      imageUrl = (json['overviewfiles'] as List).first['fileurl'] as String?;
    }
    // Also check courseimage field
    imageUrl ??= json['courseimage'] as String?;

    return CourseModel(
      id: json['id'] as int,
      shortName: json['shortname'] as String? ?? '',
      fullName: json['fullname'] as String? ?? '',
      displayName: json['displayname'] as String?,
      summary: json['summary'] as String?,
      summaryFormat: json['summaryformat'] as int?,
      categoryId: json['category'] as int?,
      categoryName: json['categoryname'] as String?,
      startDate: json['startdate'] as int?,
      endDate: json['enddate'] as int?,
      imageUrl: imageUrl,
      enrolledUserCount: json['enrolledusercount'] as int?,
      visible: json['visible'] == 1,
      progress: json['progress'] != null
          ? (json['progress'] as num).toDouble()
          : null,
      completed: json['completed'] as bool?,
      isFavourite: json['isfavourite'] as bool?,
      lastAccess: json['lastaccess'] as int?,
    );
  }

  /// Create from search result.
  factory CourseModel.fromSearchResult(Map<String, dynamic> json) {
    String? imageUrl;
    if (json['overviewfiles'] is List &&
        (json['overviewfiles'] as List).isNotEmpty) {
      imageUrl = (json['overviewfiles'] as List).first['fileurl'] as String?;
    }
    imageUrl ??= json['courseimage'] as String?;

    return CourseModel(
      id: json['id'] as int,
      shortName: json['shortname'] as String? ?? '',
      fullName: json['fullname'] as String? ?? '',
      displayName: json['displayname'] as String?,
      summary: json['summary'] as String?,
      categoryId: json['categoryid'] as int?,
      categoryName: json['categoryname'] as String?,
      imageUrl: imageUrl,
      enrolledUserCount: json['enrolledusercount'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortname': shortName,
      'fullname': fullName,
      'displayname': displayName,
      'summary': summary,
      'category': categoryId,
      'categoryname': categoryName,
      'startdate': startDate,
      'enddate': endDate,
      'imageUrl': imageUrl,
      'enrolledusercount': enrolledUserCount,
      'visible': visible == true ? 1 : 0,
      'progress': progress,
      'completed': completed,
      'isfavourite': isFavourite,
      'lastaccess': lastAccess,
    };
  }
}

/// Category model.
class CourseCategoryModel extends CourseCategory {
  const CourseCategoryModel({
    required super.id,
    required super.name,
    super.description,
    super.parent,
    super.courseCount,
    super.depth,
  });

  factory CourseCategoryModel.fromJson(Map<String, dynamic> json) {
    return CourseCategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      parent: json['parent'] as int?,
      courseCount: json['coursecount'] as int? ?? 0,
      depth: json['depth'] as int? ?? 0,
    );
  }
}
