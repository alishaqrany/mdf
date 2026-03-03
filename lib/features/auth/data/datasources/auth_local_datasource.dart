import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Local data source for caching auth state.
abstract class AuthLocalDataSource {
  /// Save user data locally.
  Future<void> saveUser(UserModel user);

  /// Get cached user data.
  Future<UserModel?> getCachedUser();

  /// Check if user is logged in.
  Future<bool> isLoggedIn();

  /// Clear all local auth data.
  Future<void> clearAuth();

  /// Save server URL.
  Future<void> saveServerUrl(String url);

  /// Get saved server URL.
  Future<String?> getServerUrl();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  AuthLocalDataSourceImpl({
    required this.secureStorage,
    required this.sharedPreferences,
  });

  @override
  Future<void> saveUser(UserModel user) async {
    await sharedPreferences.setString(
      AppConstants.userDataKey,
      user.toJsonString(),
    );
  }

  @override
  Future<UserModel?> getCachedUser() async {
    final jsonString = sharedPreferences.getString(AppConstants.userDataKey);
    if (jsonString == null) return null;
    return UserModel.fromJsonString(jsonString);
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> clearAuth() async {
    await secureStorage.delete(key: AppConstants.tokenKey);
    await secureStorage.delete(key: AppConstants.privateTokenKey);
    await secureStorage.delete(key: AppConstants.serviceNameKey);
    await sharedPreferences.remove(AppConstants.userDataKey);
  }

  @override
  Future<void> saveServerUrl(String url) async {
    await secureStorage.write(key: AppConstants.serverUrlKey, value: url);
  }

  @override
  Future<String?> getServerUrl() async {
    return secureStorage.read(key: AppConstants.serverUrlKey);
  }
}
