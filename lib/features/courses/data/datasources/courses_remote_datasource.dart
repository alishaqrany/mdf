import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/course_model.dart';

/// Remote data source for courses.
abstract class CoursesRemoteDataSource {
  Future<List<CourseModel>> getEnrolledCourses(int userId);
  Future<List<CourseModel>> getRecentCourses(int userId);
  Future<List<CourseModel>> searchCourses(String query);
  Future<List<CourseModel>> getAllCourses();
  Future<List<CourseCategoryModel>> getCategories();
  Future<CourseModel> getCourseById(int courseId);
}

class CoursesRemoteDataSourceImpl implements CoursesRemoteDataSource {
  final MoodleApiClient apiClient;

  CoursesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CourseModel>> getEnrolledCourses(int userId) async {
    // Resolve userId=0 — happens if auth state was not ready when page loaded
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return [];

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getUsersCourses,
        params: {'userid': resolvedUserId},
      );

      if (response is List) {
        return response
            .map(
              (json) =>
                  CourseModel.fromEnrolledCourse(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (_) {
      // Safe fallback 1: timeline endpoint (enrolled-only view).
      try {
        final timeline = await apiClient.call(
          MoodleApiEndpoints.getCoursesByTimeline,
          params: {
            'classification': 'all',
            'sort': 'fullname',
            'offset': 0,
            'limit': 200,
          },
        );

        if (timeline is Map && timeline['courses'] is List) {
          final courses = (timeline['courses'] as List)
              .map(
                (json) => CourseModel.fromEnrolledCourse(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
          if (courses.isNotEmpty) return courses;
        }
      } catch (_) {}

      // Safe fallback 2: recent courses endpoint (also enrolled-only).
      try {
        final recent = await apiClient.call(
          MoodleApiEndpoints.getRecentCourses,
          params: {'userid': resolvedUserId, 'limit': 50},
        );

        if (recent is List) {
          return recent
              .map(
                (json) => CourseModel.fromEnrolledCourse(
                  json as Map<String, dynamic>,
                ),
              )
              .toList();
        }
      } catch (_) {}

      return [];
    }
  }

  @override
  Future<List<CourseModel>> getRecentCourses(int userId) async {
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return [];

    final response = await apiClient.call(
      MoodleApiEndpoints.getRecentCourses,
      params: {'userid': resolvedUserId, 'limit': 5},
    );

    if (response is List) {
      return response
          .map(
            (json) =>
                CourseModel.fromEnrolledCourse(json as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<List<CourseModel>> searchCourses(String query) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.searchCourses,
      params: {'criterianame': 'search', 'criteriavalue': query},
    );

    if (response is Map && response.containsKey('courses')) {
      return (response['courses'] as List)
          .map(
            (json) =>
                CourseModel.fromSearchResult(json as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<List<CourseModel>> getAllCourses() async {
    try {
      final response = await apiClient.call(MoodleApiEndpoints.getCourses);

      if (response is List) {
        return response
            .map(
              (json) =>
                  CourseModel.fromEnrolledCourse(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (_) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      final userId = (siteInfo as Map<String, dynamic>)['userid'] as int?;
      if (userId == null) return [];

      final enrolledResponse = await apiClient.call(
        MoodleApiEndpoints.getUsersCourses,
        params: {'userid': userId},
      );

      if (enrolledResponse is List) {
        return enrolledResponse
            .map(
              (json) =>
                  CourseModel.fromEnrolledCourse(json as Map<String, dynamic>),
            )
            .toList();
      }
    }

    return [];
  }

  @override
  Future<List<CourseCategoryModel>> getCategories() async {
    final response = await apiClient.call(MoodleApiEndpoints.getCategories);

    if (response is List) {
      return response
          .map(
            (json) =>
                CourseCategoryModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<CourseModel> getCourseById(int courseId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getCoursesByField,
      params: {'field': 'id', 'value': courseId},
    );

    if (response is Map && response.containsKey('courses')) {
      final courses = response['courses'] as List;
      if (courses.isNotEmpty) {
        return CourseModel.fromEnrolledCourse(
          courses.first as Map<String, dynamic>,
        );
      }
    }
    throw Exception('Course not found');
  }
}
