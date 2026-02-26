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
    final response = await apiClient.call(
      MoodleApiEndpoints.getCourseContents,
      params: {'courseid': courseId},
    );

    if (response is List) {
      return response
          .map(
            (json) => CourseSectionModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<void> updateActivityCompletion(int cmId, bool completed) async {
    await apiClient.call(
      MoodleApiEndpoints.updateActivityCompletion,
      params: {'cmid': cmId, 'completed': completed ? 1 : 0},
    );
  }
}
