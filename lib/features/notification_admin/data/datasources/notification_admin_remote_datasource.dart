import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';

/// Remote data source for admin notification management.
abstract class NotificationAdminRemoteDataSource {
  /// Send notifications to a list of user IDs.
  Future<Map<String, dynamic>> sendNotification({
    required List<int> userIds,
    required String subject,
    required String message,
    bool sendFcm,
  });

  /// Get paginated notification log.
  Future<Map<String, dynamic>> getNotificationLog({
    int page,
    int perPage,
    String? status,
  });

  /// Search users with optional course/cohort filter.
  Future<Map<String, dynamic>> getUsers({
    String? search,
    int? courseId,
    int? cohortId,
    int page,
    int perPage,
  });
}

class NotificationAdminRemoteDataSourceImpl
    implements NotificationAdminRemoteDataSource {
  final MoodleApiClient _apiClient;

  NotificationAdminRemoteDataSourceImpl({required MoodleApiClient apiClient})
    : _apiClient = apiClient;

  @override
  Future<Map<String, dynamic>> sendNotification({
    required List<int> userIds,
    required String subject,
    required String message,
    bool sendFcm = true,
  }) async {
    // 1. Send Moodle internal notification.
    final moodleParams = <String, dynamic>{
      'subject': subject,
      'fullmessage': message,
    };
    for (int i = 0; i < userIds.length; i++) {
      moodleParams['userids[$i]'] = userIds[i];
    }
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfSendMoodleNotification,
      params: moodleParams,
    );

    // 2. Also send FCM push notification if requested.
    if (sendFcm) {
      try {
        final fcmParams = <String, dynamic>{
          'title': subject,
          'body': message.length > 300
              ? '${message.substring(0, 297)}...'
              : message,
        };
        for (int i = 0; i < userIds.length; i++) {
          fcmParams['userids[$i]'] = userIds[i];
        }
        await _apiClient.call(
          MoodleApiEndpoints.mdfSendPushNotification,
          params: fcmParams,
        );
      } catch (_) {
        // FCM push is best-effort — don't fail the whole operation
      }
    }

    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> getNotificationLog({
    int page = 0,
    int perPage = 20,
    String? status,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfGetNotificationLog,
      params: {
        'page': page,
        'perpage': perPage,
        if (status != null) 'status': status,
      },
    );
    return Map<String, dynamic>.from(result);
  }

  @override
  Future<Map<String, dynamic>> getUsers({
    String? search,
    int? courseId,
    int? cohortId,
    int page = 0,
    int perPage = 50,
  }) async {
    final result = await _apiClient.call(
      MoodleApiEndpoints.mdfGetUsersList,
      params: {
        'page': page,
        'perpage': perPage,
        if (search != null && search.isNotEmpty) 'search': search,
        if (courseId != null) 'courseid': courseId,
        if (cohortId != null) 'cohortid': cohortId,
      },
    );
    return Map<String, dynamic>.from(result);
  }
}
