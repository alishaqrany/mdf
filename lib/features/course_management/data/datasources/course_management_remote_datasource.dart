import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';

/// Remote data source for course content management (sections & activities).
abstract class CourseManagementRemoteDataSource {
  // ─── Sections ───
  Future<Map<String, dynamic>> addSection({
    required int courseId,
    required String name,
    String? summary,
  });

  Future<Map<String, dynamic>> updateSection({
    required int sectionId,
    String? name,
    String? summary,
    int? visible,
  });

  Future<Map<String, dynamic>> deleteSection({
    required int courseId,
    required int sectionId,
  });

  Future<Map<String, dynamic>> moveSection({
    required int courseId,
    required int sectionId,
    required int position,
  });

  // ─── Modules (Activities & Resources) ───
  Future<Map<String, dynamic>> addModule({
    required int courseId,
    required int sectionNum,
    required String moduleName,
    required String name,
    String? intro,
    Map<String, dynamic>? config,
  });

  Future<Map<String, dynamic>> updateModule({
    required int cmid,
    String? name,
    String? intro,
    int? visible,
    Map<String, dynamic>? config,
  });

  Future<Map<String, dynamic>> deleteModule({required int cmid});

  Future<Map<String, dynamic>> moveModule({
    required int cmid,
    required int sectionId,
    int? beforeMod,
  });
}

class CourseManagementRemoteDataSourceImpl
    implements CourseManagementRemoteDataSource {
  final MoodleApiClient _apiClient;

  CourseManagementRemoteDataSourceImpl({required MoodleApiClient apiClient})
      : _apiClient = apiClient;

  // ─── Sections ───

  @override
  Future<Map<String, dynamic>> addSection({
    required int courseId,
    required String name,
    String? summary,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfManageCourseSection,
      params: {
        'courseid': courseId,
        'action': 'add',
        'name': name,
        if (summary != null) 'summary': summary,
      },
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> updateSection({
    required int sectionId,
    String? name,
    String? summary,
    int? visible,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfManageCourseSection,
      params: {
        'sectionid': sectionId,
        'action': 'edit',
        if (name != null) 'name': name,
        if (summary != null) 'summary': summary,
        if (visible != null) 'visible': visible,
      },
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> deleteSection({
    required int courseId,
    required int sectionId,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfManageCourseSection,
      params: {
        'courseid': courseId,
        'sectionid': sectionId,
        'action': 'delete',
      },
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> moveSection({
    required int courseId,
    required int sectionId,
    required int position,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfManageCourseSection,
      params: {
        'courseid': courseId,
        'sectionid': sectionId,
        'action': 'move',
        'position': position,
      },
    );
    return Map<String, dynamic>.from(result);
  }

  // ─── Modules ───

  @override
  Future<Map<String, dynamic>> addModule({
    required int courseId,
    required int sectionNum,
    required String moduleName,
    required String name,
    String? intro,
    Map<String, dynamic>? config,
  }) async {
    final params = <String, dynamic>{
      'courseid': courseId,
      'sectionnum': sectionNum,
      'modulename': moduleName,
      'name': name,
      if (intro != null) 'intro': intro,
    };
    if (config != null) {
      // Flatten config map for Moodle POST params
      for (final entry in config.entries) {
        params['config[${entry.key}]'] = entry.value;
      }
    }
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfAddCourseModule,
      params: params,
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> updateModule({
    required int cmid,
    String? name,
    String? intro,
    int? visible,
    Map<String, dynamic>? config,
  }) async {
    final params = <String, dynamic>{
      'cmid': cmid,
      if (name != null) 'name': name,
      if (intro != null) 'intro': intro,
      if (visible != null) 'visible': visible,
    };
    if (config != null) {
      for (final entry in config.entries) {
        params['config[${entry.key}]'] = entry.value;
      }
    }
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfUpdateCourseModule,
      params: params,
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> deleteModule({required int cmid}) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfDeleteCourseModule,
      params: {'cmid': cmid},
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> moveModule({
    required int cmid,
    required int sectionId,
    int? beforeMod,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfReorderCourseModules,
      params: {
        'cmid': cmid,
        'sectionid': sectionId,
        if (beforeMod != null) 'beforemod': beforeMod,
      },
    );
    return Map<String, dynamic>.from(result);
  }
}
