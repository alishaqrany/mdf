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
    return getSiteInfo();
  }

  @override
  Future<UserModel> getSiteInfo() async {
    final response = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
    return UserModel.fromSiteInfo(response as Map<String, dynamic>);
  }
}
