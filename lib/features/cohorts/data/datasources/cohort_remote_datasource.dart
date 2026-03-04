import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../models/cohort_model.dart';

/// Remote data source for cohort management.
abstract class CohortRemoteDataSource {
  /// Get paginated list of system cohorts with member counts.
  Future<({List<CohortModel> cohorts, int total})> getCohorts({
    String search = '',
    int page = 0,
    int perpage = 50,
  });

  /// Get members of a specific cohort.
  Future<List<CohortMemberModel>> getCohortMembers({required int cohortid});

  /// Bulk add users to a cohort.
  Future<Map<String, dynamic>> addCohortMembers({
    required int cohortid,
    required List<int> userids,
  });

  /// Bulk remove users from a cohort.
  Future<Map<String, dynamic>> removeCohortMembers({
    required int cohortid,
    required List<int> userids,
  });

  /// Create a new system-level cohort.
  Future<Map<String, dynamic>> createCohort({
    required String name,
    String idnumber = '',
    String description = '',
    bool visible = true,
  });

  /// Delete a cohort by ID.
  Future<Map<String, dynamic>> deleteCohort({required int cohortid});

  /// Sync a cohort to a course (enable cohort enrolment method).
  Future<Map<String, dynamic>> syncCohortToCourse({
    required int cohortid,
    required int courseid,
    int roleid = 5,
  });

  /// Remove cohort enrolment from a course.
  Future<Map<String, dynamic>> unsyncCohortFromCourse({
    required int cohortid,
    required int courseid,
  });

  /// Get courses synced with a cohort.
  Future<List<CohortCourseSyncModel>> getCohortCourseSyncs({
    required int cohortid,
  });
}

class CohortRemoteDataSourceImpl implements CohortRemoteDataSource {
  final MoodleApiClient apiClient;

  CohortRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<({List<CohortModel> cohorts, int total})> getCohorts({
    String search = '',
    int page = 0,
    int perpage = 50,
  }) async {
    final params = <String, dynamic>{'page': page, 'perpage': perpage};
    if (search.isNotEmpty) params['search'] = search;

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCohorts,
      params: params,
    );

    if (response is Map<String, dynamic>) {
      final cohorts = (response['cohorts'] as List? ?? [])
          .map((e) => CohortModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = response['total'] as int? ?? cohorts.length;
      return (cohorts: cohorts, total: total);
    }
    return (cohorts: <CohortModel>[], total: 0);
  }

  @override
  Future<List<CohortMemberModel>> getCohortMembers({
    required int cohortid,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCohortMembers,
      params: {'cohortid': cohortid},
    );

    if (response is Map<String, dynamic> && response.containsKey('members')) {
      return (response['members'] as List)
          .map((e) => CohortMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (response is List) {
      return response
          .map((e) => CohortMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<Map<String, dynamic>> addCohortMembers({
    required int cohortid,
    required List<int> userids,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfAddCohortMembers,
      params: {
        'cohortid': cohortid,
        for (int i = 0; i < userids.length; i++) 'userids[$i]': userids[i],
      },
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<Map<String, dynamic>> removeCohortMembers({
    required int cohortid,
    required List<int> userids,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfRemoveCohortMembers,
      params: {
        'cohortid': cohortid,
        for (int i = 0; i < userids.length; i++) 'userids[$i]': userids[i],
      },
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<Map<String, dynamic>> createCohort({
    required String name,
    String idnumber = '',
    String description = '',
    bool visible = true,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfCreateCohort,
      params: {
        'name': name,
        'idnumber': idnumber,
        'description': description,
        'visible': visible ? 1 : 0,
      },
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<Map<String, dynamic>> deleteCohort({required int cohortid}) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfDeleteCohort,
      params: {'cohortid': cohortid},
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<Map<String, dynamic>> syncCohortToCourse({
    required int cohortid,
    required int courseid,
    int roleid = 5,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfSyncCohortToCourse,
      params: {
        'cohortid': cohortid,
        'courseid': courseid,
        'roleid': roleid,
      },
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<Map<String, dynamic>> unsyncCohortFromCourse({
    required int cohortid,
    required int courseid,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfUnsyncCohortFromCourse,
      params: {'cohortid': cohortid, 'courseid': courseid},
    );
    return response is Map<String, dynamic> ? response : {'success': true};
  }

  @override
  Future<List<CohortCourseSyncModel>> getCohortCourseSyncs({
    required int cohortid,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCohortCourseSyncs,
      params: {'cohortid': cohortid},
    );

    if (response is Map<String, dynamic> && response.containsKey('syncs')) {
      return (response['syncs'] as List)
          .map(
            (e) => CohortCourseSyncModel.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }
}
