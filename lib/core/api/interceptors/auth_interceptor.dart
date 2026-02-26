import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../constants/app_constants.dart';

/// Interceptor that automatically adds the auth token to every Moodle API request.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only add token to Moodle REST API calls
    if (options.path.contains(AppConstants.moodleRestPath) ||
        options.path.contains(AppConstants.moodleUploadPath) ||
        options.path.contains(AppConstants.moodlePluginFilePath)) {
      final token = await _secureStorage.read(key: AppConstants.tokenKey);
      if (token != null) {
        if (options.data is Map) {
          (options.data as Map)['wstoken'] = token;
        } else if (options.data is FormData) {
          // For file uploads
        } else {
          options.data = {'wstoken': token};
        }
      }
    }
    handler.next(options);
  }
}
