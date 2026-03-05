import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/course_content_model.dart';

abstract class CourseContentRemoteDataSource {
  Future<List<CourseSectionModel>> getCourseContents(int courseId);
  Future<void> updateActivityCompletion(int cmId, bool completed);
}

class CourseContentRemoteDataSourceImpl
    implements CourseContentRemoteDataSource {
  final MoodleApiClient apiClient;

  CourseContentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CourseSectionModel>> getCourseContents(int courseId) async {
    // First, register the course view to ensure access is granted
    try {
      await apiClient.call(
        MoodleApiEndpoints.viewCourse,
        params: {'courseid': courseId},
      );
    } catch (_) {
      // viewCourse may fail if user lacks access — continue anyway
    }

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getCourseContents,
        params: {'courseid': courseId},
      );

      if (response is List) {
        return response
            .map(
              (json) =>
                  CourseSectionModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      // If access denied, try self-enrol first, then retry
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('accessexception') ||
          errStr.contains('requireloginerror') ||
          errStr.contains('nopermissions')) {
        try {
          await apiClient.call(
            MoodleApiEndpoints.selfEnrolUser,
            params: {'courseid': courseId},
          );
          // Retry after self-enrol
          final response = await apiClient.call(
            MoodleApiEndpoints.getCourseContents,
            params: {'courseid': courseId},
          );
          if (response is List) {
            return response
                .map(
                  (json) => CourseSectionModel.fromJson(
                    json as Map<String, dynamic>,
                  ),
                )
                .toList();
          }
        } catch (_) {
          // Self-enrol not available — rethrow original error
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> updateActivityCompletion(int cmId, bool completed) async {
    await apiClient.call(
      MoodleApiEndpoints.updateActivityCompletion,
      params: {'cmid': cmId, 'completed': completed ? 1 : 0},
    );
  }
}
