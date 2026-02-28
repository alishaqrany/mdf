import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/enrolled_user_model.dart';

abstract class EnrollmentRemoteDataSource {
  Future<List<EnrolledUserModel>> getEnrolledUsers(int courseId);
  Future<void> enrollUser({
    required int courseId,
    required int userId,
    required int roleId,
  });
  Future<void> bulkEnrollUsers({
    required int courseId,
    required List<int> userIds,
    required int roleId,
  });
  Future<void> unenrollUser({required int courseId, required int userId});
  Future<void> assignRole({
    required int userId,
    required int roleId,
    required int contextId,
  });
  Future<void> unassignRole({
    required int userId,
    required int roleId,
    required int contextId,
  });
}

class EnrollmentRemoteDataSourceImpl implements EnrollmentRemoteDataSource {
  final MoodleApiClient apiClient;

  EnrollmentRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<EnrolledUserModel>> getEnrolledUsers(int courseId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getEnrolledUsers,
      params: {'courseid': courseId},
    );

    if (response is List) {
      return response
          .map((u) => EnrolledUserModel.fromJson(u as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> enrollUser({
    required int courseId,
    required int userId,
    required int roleId,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.manualEnrolUsers,
      params: {
        'enrolments[0][roleid]': roleId,
        'enrolments[0][userid]': userId,
        'enrolments[0][courseid]': courseId,
      },
    );
  }

  @override
  Future<void> bulkEnrollUsers({
    required int courseId,
    required List<int> userIds,
    required int roleId,
  }) async {
    final params = <String, dynamic>{};
    for (int i = 0; i < userIds.length; i++) {
      params['enrolments[$i][roleid]'] = roleId;
      params['enrolments[$i][userid]'] = userIds[i];
      params['enrolments[$i][courseid]'] = courseId;
    }
    await apiClient.call(MoodleApiEndpoints.manualEnrolUsers, params: params);
  }

  @override
  Future<void> unenrollUser({
    required int courseId,
    required int userId,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.manualUnenrolUsers,
      params: {
        'enrolments[0][userid]': userId,
        'enrolments[0][courseid]': courseId,
      },
    );
  }

  @override
  Future<void> assignRole({
    required int userId,
    required int roleId,
    required int contextId,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.assignRoles,
      params: {
        'assignments[0][roleid]': roleId,
        'assignments[0][userid]': userId,
        'assignments[0][contextid]': contextId,
      },
    );
  }

  @override
  Future<void> unassignRole({
    required int userId,
    required int roleId,
    required int contextId,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.unassignRoles,
      params: {
        'unassignments[0][roleid]': roleId,
        'unassignments[0][userid]': userId,
        'unassignments[0][contextid]': contextId,
      },
    );
  }
}
