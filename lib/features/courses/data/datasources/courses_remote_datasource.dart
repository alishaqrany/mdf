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
    final response = await apiClient.call(
      MoodleApiEndpoints.getUsersCourses,
      params: {'userid': userId},
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
  Future<List<CourseModel>> getRecentCourses(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getRecentCourses,
      params: {'userid': userId, 'limit': 5},
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
