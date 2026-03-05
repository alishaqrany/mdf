import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/protection_settings.dart';
import '../../domain/entities/user_device.dart';
import '../../domain/entities/protection_log_entry.dart';

/// Remote data source for content protection features.
abstract class ContentProtectionRemoteDataSource {
  // ─── Settings ───
  Future<ProtectionSettings> getProtectionSettings();
  Future<void> saveProtectionSettings(ProtectionSettings settings);

  // ─── Device Management ───
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String osVersion,
    required String appVersion,
  });
  Future<List<UserDevice>> getUserDevices(int userId);
  Future<void> revokeDevice(int deviceRecordId);
  Future<void> revokeAllDevices(int userId);
  Future<void> setUserDeviceLimit(int userId, int maxDevices);
  Future<int> getUserDeviceLimit(int userId);

  // ─── Protection Log ───
  Future<Map<String, dynamic>> getProtectionLog({
    int page = 0,
    int perPage = 50,
    String? action,
    int? userId,
  });

  // ─── Validation ───
  Future<Map<String, dynamic>> validateDeviceAccess(String deviceId);
}

class ContentProtectionRemoteDataSourceImpl
    implements ContentProtectionRemoteDataSource {
  final MoodleApiClient apiClient;

  ContentProtectionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ProtectionSettings> getProtectionSettings() async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetProtectionSettings,
    );
    if (response is Map<String, dynamic>) {
      return ProtectionSettings.fromJson(response);
    }
    return const ProtectionSettings();
  }

  @override
  Future<void> saveProtectionSettings(ProtectionSettings settings) async {
    final courseIds = settings.protectedCourseIds.isNotEmpty
        ? settings.protectedCourseIds.join(',')
        : '';
    final contentTypes = settings.protectedContentTypes.isNotEmpty
        ? settings.protectedContentTypes.join(',')
        : '';

    await apiClient.call(
      MoodleApiEndpoints.mdfSaveProtectionSettings,
      params: {
        'enabled': settings.enabled ? 1 : 0,
        'prevent_screen_capture': settings.preventScreenCapture ? 1 : 0,
        'prevent_screen_recording': settings.preventScreenRecording ? 1 : 0,
        'watermark_enabled': settings.watermarkEnabled ? 1 : 0,
        'default_max_devices': settings.defaultMaxDevices,
        'protected_course_ids': courseIds,
        'protected_content_types': contentTypes,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> registerDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String osVersion,
    required String appVersion,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfRegisterDevice,
      params: {
        'device_id': deviceId,
        'device_name': deviceName,
        'platform': platform,
        'os_version': osVersion,
        'app_version': appVersion,
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'status': 'ok'};
  }

  @override
  Future<List<UserDevice>> getUserDevices(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetUserDevices,
      params: {'userid': userId},
    );
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map((e) => UserDevice.fromJson(e))
          .toList();
    }
    if (response is Map && response.containsKey('devices')) {
      return (response['devices'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => UserDevice.fromJson(e))
          .toList();
    }
    return [];
  }

  @override
  Future<void> revokeDevice(int deviceRecordId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfRevokeDevice,
      params: {'id': deviceRecordId},
    );
  }

  @override
  Future<void> revokeAllDevices(int userId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfRevokeAllDevices,
      params: {'userid': userId},
    );
  }

  @override
  Future<void> setUserDeviceLimit(int userId, int maxDevices) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfSetUserDeviceLimit,
      params: {'userid': userId, 'max_devices': maxDevices},
    );
  }

  @override
  Future<int> getUserDeviceLimit(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetUserDeviceLimit,
      params: {'userid': userId},
    );
    if (response is Map<String, dynamic>) {
      return response['max_devices'] as int? ?? 2;
    }
    return 2;
  }

  @override
  Future<Map<String, dynamic>> getProtectionLog({
    int page = 0,
    int perPage = 50,
    String? action,
    int? userId,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'perpage': perPage,
    };
    if (action != null) params['action'] = action;
    if (userId != null) params['userid'] = userId;

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetProtectionLog,
      params: params,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'logs': [], 'total': 0};
  }

  @override
  Future<Map<String, dynamic>> validateDeviceAccess(String deviceId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfValidateDeviceAccess,
      params: {'device_id': deviceId},
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'allowed': true};
  }
}
