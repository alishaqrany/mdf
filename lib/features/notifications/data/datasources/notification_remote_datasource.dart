import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<AppNotificationModel>> getNotifications(int userId);
  Future<int> getUnreadCount(int userId);
  Future<void> markNotificationRead(int notificationId);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final MoodleApiClient apiClient;

  NotificationRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<AppNotificationModel>> getNotifications(int userId) async {
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return [];

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getPopupNotifications,
        params: {'useridto': resolvedUserId},
      );

      if (response is Map && response.containsKey('notifications')) {
        return (response['notifications'] as List)
            .map(
              (j) => AppNotificationModel.fromJson(j as Map<String, dynamic>),
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<int> getUnreadCount(int userId) async {
    int resolvedUserId = userId;
    if (resolvedUserId == 0) {
      final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
      resolvedUserId =
          (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
    }
    if (resolvedUserId == 0) return 0;

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getUnreadNotificationCount,
        params: {'useridto': resolvedUserId},
      );
      if (response is int) return response;
      if (response is Map) {
        return (response['count'] as int?) ??
            (response['unreadcount'] as int?) ??
            0;
      }
    } catch (_) {}
    return 0;
  }

  @override
  Future<void> markNotificationRead(int notificationId) async {
    await apiClient.call(
      MoodleApiEndpoints.markNotificationRead,
      params: {'notificationid': notificationId},
    );
  }
}
