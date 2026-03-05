import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
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

  int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  Map<String, dynamic>? _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((key, val) => MapEntry('$key', val)),
      );
    }
    return null;
  }

  List<CourseModel> _parseCourseList(dynamic response, {String? listKey}) {
    List<dynamic>? rawList;

    if (response is List) {
      rawList = response;
    } else if (response is Map &&
        listKey != null &&
        response[listKey] is List) {
      rawList = response[listKey] as List;
    }

    if (rawList == null) return [];

    final courses = <CourseModel>[];
    for (final item in rawList) {
      final map = _asStringMap(item);
      if (map != null) {
        courses.add(CourseModel.fromEnrolledCourse(map));
      }
    }
    return courses;
  }

  bool _isInvalidRecordUnknown(Object error) {
    if (error is MoodleException) {
      return error.errorCode == 'invalidrecordunknown';
    }
    if (error is ServerException) {
      return error.errorCode == 'invalidrecordunknown' ||
          error.message.contains('invalidrecordunknown');
    }
    return false;
  }

  Future<int> _resolveCurrentUserId() async {
    final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
    final siteInfoMap = _asStringMap(siteInfo);
    return _parseInt(siteInfoMap?['userid']);
  }

  Future<List<CourseModel>> _loadEnrolledCoursesForUserId(
    int resolvedUserId,
  ) async {
    // Track errors only from strategies that truly matter.
    // When a strategy succeeds (no exception) but returns empty, that means
    // the API call worked — we clear the error because the user simply has
    // no courses via that endpoint.
    Object? lastError;
    bool anyStrategySucceeded = false;

    // ─── Strategy 1: enrol_get_users_courses (most basic & reliable) ───
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getUsersCourses,
        params: {'userid': resolvedUserId},
      );
      anyStrategySucceeded = true;
      final courses = _parseCourseList(response);
      if (courses.isNotEmpty) return courses;
    } catch (e) {
      lastError = e;
    }

    // ─── Strategy 2: Recent courses ───
    try {
      final recent = await apiClient.call(
        MoodleApiEndpoints.getRecentCourses,
        params: {'userid': resolvedUserId, 'limit': 50},
      );
      anyStrategySucceeded = true;
      final courses = _parseCourseList(recent);
      if (courses.isNotEmpty) return courses;
    } catch (e) {
      lastError ??= e;
    }

    // ─── Strategy 3: Timeline 'all' ───
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
      anyStrategySucceeded = true;
      final courses = _parseCourseList(timeline, listKey: 'courses');
      if (courses.isNotEmpty) return courses;
    } catch (e) {
      // Timeline may not be available for this service token; don't mask
      // earlier successes.
      lastError ??= e;
    }

    // ─── Strategy 4: Timeline 'inprogress' ───
    try {
      final timeline = await apiClient.call(
        MoodleApiEndpoints.getCoursesByTimeline,
        params: {
          'classification': 'inprogress',
          'sort': 'fullname',
          'offset': 0,
          'limit': 200,
        },
      );
      anyStrategySucceeded = true;
      final courses = _parseCourseList(timeline, listKey: 'courses');
      if (courses.isNotEmpty) return courses;
    } catch (e) {
      lastError ??= e;
    }

    // If at least one strategy executed without an exception, the API is
    // reachable and the user account is valid — return empty list.
    if (anyStrategySucceeded) return [];

    // ALL strategies threw exceptions — propagate a meaningful error.
    if (lastError != null) {
      if (lastError is ServerException) throw lastError;
      if (lastError is MoodleException) {
        throw ServerException(
          message: 'خطأ من المنصة: ${(lastError as MoodleException).message}',
          errorCode: (lastError as MoodleException).errorCode,
        );
      }
      throw ServerException(
        message:
            'فشل تحميل المقررات. تحقق من اتصالك أو أعد تسجيل الدخول.\n'
            'Failed to load courses: $lastError',
      );
    }

    return [];
  }

  @override
  Future<List<CourseModel>> getEnrolledCourses(int userId) async {
    // Resolve userId=0 — happens if auth state was not ready when page loaded
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      try {
        resolvedUserId = await _resolveCurrentUserId();
      } catch (e) {
        // If we can't even get site info, rethrow — connectivity/auth issue
        throw ServerException(
          message:
              'فشل الاتصال بالخادم. تحقق من اتصال الإنترنت أو أعد تسجيل الدخول.\n'
              'Failed to connect. Check your connection or re-login.',
        );
      }
    }
    if (resolvedUserId == 0) {
      throw const ServerException(
        message:
            'لم يتم التعرف على المستخدم. أعد تسجيل الدخول.\n'
            'User not identified. Please re-login.',
      );
    }
    try {
      return await _loadEnrolledCoursesForUserId(resolvedUserId);
    } on ServerException catch (e) {
      if (_isInvalidRecordUnknown(e)) {
        // Fallback: auth state may carry a stale userId for this token/site.
        final currentUserId = await _resolveCurrentUserId();
        if (currentUserId > 0 && currentUserId != resolvedUserId) {
          return _loadEnrolledCoursesForUserId(currentUserId);
        }
      }
      rethrow;
    } catch (e) {
      if (_isInvalidRecordUnknown(e)) {
        final currentUserId = await _resolveCurrentUserId();
        if (currentUserId > 0 && currentUserId != resolvedUserId) {
          return _loadEnrolledCoursesForUserId(currentUserId);
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<CourseModel>> getRecentCourses(int userId) async {
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return [];

    final response = await apiClient.call(
      MoodleApiEndpoints.getRecentCourses,
      params: {'userid': resolvedUserId, 'limit': 5},
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
    try {
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
    } catch (_) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      final userId = (siteInfo as Map<String, dynamic>)['userid'] as int?;
      if (userId == null) return [];

      final enrolledResponse = await apiClient.call(
        MoodleApiEndpoints.getUsersCourses,
        params: {'userid': userId},
      );

      if (enrolledResponse is List) {
        return enrolledResponse
            .map(
              (json) =>
                  CourseModel.fromEnrolledCourse(json as Map<String, dynamic>),
            )
            .toList();
      }
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
