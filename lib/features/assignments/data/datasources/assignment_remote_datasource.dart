import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/assignment_model.dart';

abstract class AssignmentRemoteDataSource {
  Future<List<AssignmentModel>> getAssignmentsByCourse(int courseId);
  Future<List<AssignmentSubmissionModel>> getSubmissions(int assignmentId);
  Future<void> saveSubmission(
    int assignmentId,
    String? onlineText,
    int? fileItemId,
  );
  Future<void> submitForGrading(int assignmentId);
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  final MoodleApiClient apiClient;

  AssignmentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AssignmentModel>> getAssignmentsByCourse(int courseId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getAssignments,
      params: {'courseids[0]': courseId},
    );

    if (response is Map && response.containsKey('courses')) {
      final courses = response['courses'] as List;
      if (courses.isNotEmpty) {
        final assignments =
            (courses.first as Map<String, dynamic>)['assignments'] as List? ??
            [];
        return assignments
            .map((j) => AssignmentModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  @override
  Future<List<AssignmentSubmissionModel>> getSubmissions(
    int assignmentId,
  ) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getSubmissions,
      params: {'assignmentids[0]': assignmentId},
    );

    if (response is Map && response.containsKey('assignments')) {
      final assignments = response['assignments'] as List;
      if (assignments.isNotEmpty) {
        final subs =
            (assignments.first as Map<String, dynamic>)['submissions']
                as List? ??
            [];
        return subs
            .map(
              (j) =>
                  AssignmentSubmissionModel.fromJson(j as Map<String, dynamic>),
            )
            .toList();
      }
    }
    return [];
  }

  @override
  Future<void> saveSubmission(
    int assignmentId,
    String? onlineText,
    int? fileItemId,
  ) async {
    final params = <String, dynamic>{'assignmentid': assignmentId};
    if (onlineText != null) {
      params['plugindata[onlinetext_editor][text]'] = onlineText;
      params['plugindata[onlinetext_editor][format]'] = 1;
      params['plugindata[onlinetext_editor][itemid]'] = 0;
    }
    if (fileItemId != null) {
      params['plugindata[files_filemanager]'] = fileItemId;
    }
    await apiClient.call(MoodleApiEndpoints.saveSubmission, params: params);
  }

  @override
  Future<void> submitForGrading(int assignmentId) async {
    await apiClient.call(
      MoodleApiEndpoints.submitForGrading,
      params: {'assignmentid': assignmentId},
    );
  }
}
