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
    super.contacts,
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

    // Parse course contacts/teachers
    final contactsList = <CourseContact>[];
    if (json['contacts'] is List) {
      for (final c in json['contacts'] as List) {
        if (c is Map<String, dynamic>) {
          contactsList.add(
            CourseContact(
              id: c['id'] as int? ?? 0,
              fullName: c['fullname'] as String? ?? '',
              profileImageUrl: c['profileimageurl'] as String?,
            ),
          );
        }
      }
    }

    return CourseModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      shortName: json['shortname']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      displayName: json['displayname']?.toString(),
      summary: json['summary']?.toString(),
      summaryFormat: json['summaryformat'] is int ? json['summaryformat'] as int : int.tryParse(json['summaryformat'].toString()),
      categoryId: json['category'] is int ? json['category'] as int : int.tryParse(json['category'].toString()),
      categoryName: json['categoryname']?.toString(),
      startDate: json['startdate'] is int ? json['startdate'] as int : int.tryParse(json['startdate'].toString()),
      endDate: json['enddate'] is int ? json['enddate'] as int : int.tryParse(json['enddate'].toString()),
      imageUrl: imageUrl,
      enrolledUserCount: json['enrolledusercount'] is int ? json['enrolledusercount'] as int : int.tryParse(json['enrolledusercount'].toString()),
      visible: json['visible'] == 1 || json['visible'] == true || json['visible'] == '1',
      progress: json['progress'] != null
          ? double.tryParse(json['progress'].toString())
          : null,
      completed: json['completed'] == 1 || json['completed'] == true || json['completed'] == '1',
      isFavourite: json['isfavourite'] == 1 || json['isfavourite'] == true || json['isfavourite'] == '1',
      lastAccess: json['lastaccess'] is int ? json['lastaccess'] as int : int.tryParse(json['lastaccess'].toString()),
      contacts: contactsList,
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
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      shortName: json['shortname']?.toString() ?? '',
      fullName: json['fullname']?.toString() ?? '',
      displayName: json['displayname']?.toString(),
      summary: json['summary']?.toString(),
      categoryId: json['categoryid'] is int ? json['categoryid'] as int : int.tryParse(json['categoryid'].toString()),
      categoryName: json['categoryname']?.toString(),
      imageUrl: imageUrl,
      enrolledUserCount: json['enrolledusercount'] is int ? json['enrolledusercount'] as int : int.tryParse(json['enrolledusercount'].toString()),
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
