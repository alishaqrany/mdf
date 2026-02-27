import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/grade_model.dart';

abstract class GradeRemoteDataSource {
  Future<List<GradeItemModel>> getGradeItems(int courseId, int userId);
  Future<List<CourseGradeModel>> getCourseGrades(int userId);
}

class GradeRemoteDataSourceImpl implements GradeRemoteDataSource {
  final MoodleApiClient apiClient;

  GradeRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<GradeItemModel>> getGradeItems(int courseId, int userId) async {
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return [];

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getGradeItems,
        params: {'courseid': courseId, 'userid': resolvedUserId},
      );

      if (response is Map && response.containsKey('usergrades')) {
        final userGrades = response['usergrades'] as List;
        if (userGrades.isNotEmpty) {
          final gradeitems =
              (userGrades.first as Map<String, dynamic>)['gradeitems']
                  as List? ??
              [];
          return gradeitems
              .map((j) => GradeItemModel.fromJson(j as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<CourseGradeModel>> getCourseGrades(int userId) async {
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return [];

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getCourseGrades,
        params: {'userid': resolvedUserId},
      );

      if (response is Map && response.containsKey('grades')) {
        return (response['grades'] as List)
            .map((j) => CourseGradeModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
