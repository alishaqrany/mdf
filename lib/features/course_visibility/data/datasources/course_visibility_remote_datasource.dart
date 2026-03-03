import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../models/course_visibility_model.dart';

/// Remote data source for course visibility management.
abstract class CourseVisibilityRemoteDataSource {
  /// Get all visibility overrides (admin).
  Future<List<CourseVisibilityOverride>> getCourseVisibility({
    int courseid = 0,
  });

  /// Set a visibility override.
  Future<Map<String, dynamic>> setCourseVisibility({
    required int courseid,
    required String targettype,
    int targetid = 0,
    required int hidden,
  });

  /// Remove a visibility override by ID.
  Future<Map<String, dynamic>> removeCourseVisibility({required int id});

  /// Get hidden course IDs for the current user (student use).
  Future<List<int>> getHiddenCourses();
}

class CourseVisibilityRemoteDataSourceImpl
    implements CourseVisibilityRemoteDataSource {
  final MoodleApiClient apiClient;

  CourseVisibilityRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CourseVisibilityOverride>> getCourseVisibility({
    int courseid = 0,
  }) async {
    final params = <String, dynamic>{};
    if (courseid > 0) params['courseid'] = courseid;

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCourseVisibility,
      params: params,
    );

    if (response is Map<String, dynamic> && response.containsKey('overrides')) {
      return (response['overrides'] as List)
          .map(
            (e) => CourseVisibilityOverride.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    if (response is List) {
      return response
          .map(
            (e) => CourseVisibilityOverride.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> setCourseVisibility({
    required int courseid,
    required String targettype,
    int targetid = 0,
    required int hidden,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfSetCourseVisibility,
      params: {
        'courseid': courseid,
        'targettype': targettype,
        'targetid': targetid,
        'hidden': hidden,
      },
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<Map<String, dynamic>> removeCourseVisibility({required int id}) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfRemoveCourseVisibility,
      params: {'id': id},
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<List<int>> getHiddenCourses() async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetHiddenCourses,
    );

    if (response is Map<String, dynamic> && response.containsKey('courseids')) {
      return (response['courseids'] as List).map((e) => e as int).toList();
    }
    if (response is List) {
      return response.map((e) => e as int).toList();
    }
    return [];
  }
}
