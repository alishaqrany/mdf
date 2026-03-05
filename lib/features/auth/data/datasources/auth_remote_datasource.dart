import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';

/// Remote data source for authentication operations.
abstract class AuthRemoteDataSource {
  /// Login with username/password and return token + user info.
  Future<UserModel> login({
    required String serverUrl,
    required String username,
    required String password,
  });

  /// Get current user info from server.
  Future<UserModel> getSiteInfo();

  /// Get user role summary (teacher status, teacher course IDs).
  Future<Map<String, dynamic>> getUserRoleSummary();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final MoodleApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<UserModel> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    // Set server URL
    await apiClient.setBaseUrl(serverUrl);

    // Authenticate and get token
    await apiClient.login(username: username, password: password);

    // Get user info
    final user = await getSiteInfo();

    // Log which service was used for diagnostics
    final activeService = await apiClient.getActiveService();
    debugPrint('[MDF Auth] Token service: $activeService');
    if (activeService != 'mdf_mobile') {
      debugPrint(
        '[MDF Auth] WARNING: Token is from "$activeService" not "mdf_mobile". '
        'MDF features (gamification, social, user mgmt, cohorts, visibility) will fail with accessexception.',
      );
    }

    return user;
  }

  @override
  Future<UserModel> getSiteInfo() async {
    final response = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
    return UserModel.fromSiteInfo(response as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getUserRoleSummary() async {
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.mdfGetUserRoleSummary,
      );
      return response as Map<String, dynamic>;
    } catch (_) {
      // If the endpoint doesn't exist yet (plugin not updated), return defaults.
      return {'is_teacher': false, 'is_course_creator': false, 'teacher_courseids': <int>[]};
    }
  }
}
