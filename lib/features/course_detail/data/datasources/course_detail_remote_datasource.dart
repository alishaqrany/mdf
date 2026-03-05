import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/data/models/course_model.dart';

/// Data source for fetching single course details.
abstract class CourseDetailRemoteDataSource {
  Future<Course> getCourseDetail(int courseId);
}

class CourseDetailRemoteDataSourceImpl implements CourseDetailRemoteDataSource {
  final MoodleApiClient apiClient;

  CourseDetailRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<Course> getCourseDetail(int courseId) async {
    try {
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
    } catch (_) {
      // Fallback: resolve from current user's enrolled courses only
      try {
        final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
        final userId = (siteInfo as Map<String, dynamic>)['userid'] as int?;
        if (userId == null || userId == 0) {
          throw Exception('Cannot resolve current user');
        }

        final response = await apiClient.call(
          MoodleApiEndpoints.getUsersCourses,
          params: {'userid': userId},
        );

        if (response is List) {
          final match = response.cast<Map<String, dynamic>>().firstWhere(
            (c) => c['id'] == courseId,
            orElse: () => <String, dynamic>{},
          );
          if (match.isNotEmpty) {
            return CourseModel.fromEnrolledCourse(match);
          }
        }
      } catch (_) {}

      // Fallback 2: enrolled timeline endpoint.
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
          final match = (timeline['courses'] as List)
              .cast<Map<String, dynamic>>()
              .firstWhere(
                (c) => c['id'] == courseId,
                orElse: () => <String, dynamic>{},
              );
          if (match.isNotEmpty) {
            return CourseModel.fromEnrolledCourse(match);
          }
        }
      } catch (_) {}
    }

    // Return minimal course if nothing found
    return Course(id: courseId, shortName: '', fullName: '');
  }
}
