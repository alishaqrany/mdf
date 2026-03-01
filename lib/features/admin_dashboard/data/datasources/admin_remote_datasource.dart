import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../models/dashboard_stats_model.dart';
import '../models/enrollment_stats_model.dart';
import '../models/system_health_model.dart';

/// Remote data source for the MDF custom Moodle plugin APIs.
abstract class AdminRemoteDataSource {
  /// Get dashboard statistics.
  Future<DashboardStatsModel> getDashboardStats();

  /// Get enrollment/completion trends.
  Future<EnrollmentStatsModel> getEnrollmentStats({
    String period = 'month',
    int months = 6,
    int courseid = 0,
  });

  /// Get system health information.
  Future<SystemHealthModel> getSystemHealth();

  /// Get activity logs.
  Future<Map<String, dynamic>> getActivityLogs({
    int userid = 0,
    int courseid = 0,
    String component = '',
    String action = '',
    int timestart = 0,
    int timeend = 0,
    int page = 0,
    int perpage = 50,
  });

  /// Bulk enrol users into a course.
  Future<Map<String, dynamic>> bulkEnrolUsers({
    required int courseid,
    required List<int> userids,
    int roleid = 5,
    int timestart = 0,
    int timeend = 0,
  });

  /// Send push notification to users.
  Future<Map<String, dynamic>> sendPushNotification({
    required List<int> userids,
    required String title,
    required String body,
    String data = '{}',
  });

  /// Register FCM token for push notifications.
  Future<Map<String, dynamic>> registerFcmToken({
    required String token,
    required String platform,
    String devicename = '',
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final MoodleApiClient apiClient;

  AdminRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<DashboardStatsModel> getDashboardStats() async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetDashboardStats,
    );
    return DashboardStatsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<EnrollmentStatsModel> getEnrollmentStats({
    String period = 'month',
    int months = 6,
    int courseid = 0,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetEnrollmentStats,
      params: {'period': period, 'months': months, 'courseid': courseid},
    );
    return EnrollmentStatsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<SystemHealthModel> getSystemHealth() async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetSystemHealth,
    );
    return SystemHealthModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getActivityLogs({
    int userid = 0,
    int courseid = 0,
    String component = '',
    String action = '',
    int timestart = 0,
    int timeend = 0,
    int page = 0,
    int perpage = 50,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetActivityLogs,
      params: {
        'userid': userid,
        'courseid': courseid,
        'component': component,
        'action': action,
        'timestart': timestart,
        'timeend': timeend,
        'page': page,
        'perpage': perpage,
      },
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> bulkEnrolUsers({
    required int courseid,
    required List<int> userids,
    int roleid = 5,
    int timestart = 0,
    int timeend = 0,
  }) async {
    final params = <String, dynamic>{
      'courseid': courseid,
      'roleid': roleid,
      'timestart': timestart,
      'timeend': timeend,
    };
    for (int i = 0; i < userids.length; i++) {
      params['userids[$i]'] = userids[i];
    }

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfBulkEnrolUsers,
      params: params,
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> sendPushNotification({
    required List<int> userids,
    required String title,
    required String body,
    String data = '{}',
  }) async {
    final params = <String, dynamic>{
      'title': title,
      'body': body,
      'data': data,
    };
    for (int i = 0; i < userids.length; i++) {
      params['userids[$i]'] = userids[i];
    }

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfSendPushNotification,
      params: params,
    );
    return response as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> registerFcmToken({
    required String token,
    required String platform,
    String devicename = '',
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfRegisterFcmToken,
      params: {'token': token, 'platform': platform, 'devicename': devicename},
    );
    return response as Map<String, dynamic>;
  }
}
