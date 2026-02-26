import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import 'api_endpoints.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Main API client for communicating with the Moodle REST API.
///
/// All Moodle web service calls go through this client.
/// Token management and error handling are done via interceptors.
class MoodleApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();

  String? _baseUrl;

  MoodleApiClient({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(_secureStorage),
      ErrorInterceptor(),
      LoggingInterceptor(),
    ]);
  }

  /// Set the base URL for the Moodle server.
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _secureStorage.write(key: AppConstants.serverUrlKey, value: _baseUrl);
  }

  /// Get the current base URL.
  Future<String?> getBaseUrl() async {
    _baseUrl ??= await _secureStorage.read(key: AppConstants.serverUrlKey);
    return _baseUrl;
  }

  /// Authenticate user and retrieve token.
  ///
  /// Calls `/login/token.php` directly (not through REST).
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    String service = AppConstants.moodleService,
  }) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null) {
      throw const ServerException(message: 'Server URL not configured');
    }

    try {
      final response = await _dio.post(
        '$baseUrl${AppConstants.moodleLoginPath}',
        data: {
          'username': username,
          'password': password,
          'service': service,
        },
      );

      final data = response.data as Map<String, dynamic>;

      if (data.containsKey('token')) {
        // Save token
        await _secureStorage.write(
          key: AppConstants.tokenKey,
          value: data['token'] as String,
        );
        if (data.containsKey('privatetoken')) {
          await _secureStorage.write(
            key: AppConstants.privateTokenKey,
            value: data['privatetoken'] as String,
          );
        }
        return data;
      }

      throw ServerException(
        message: data['error'] as String? ?? 'Login failed',
        errorCode: data['errorcode'] as String?,
      );
    } on DioException catch (e) {
      if (e.error is ServerException) rethrow;
      if (e.error is AuthException) rethrow;
      throw ServerException(message: e.message ?? 'Login failed');
    }
  }

  /// Call a Moodle Web Service function.
  ///
  /// Example:
  /// ```dart
  /// final result = await apiClient.call(
  ///   MoodleApiEndpoints.getSiteInfo,
  /// );
  /// ```
  Future<dynamic> call(
    String wsFunction, {
    Map<String, dynamic>? params,
  }) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null) {
      throw const ServerException(message: 'Server URL not configured');
    }

    final data = <String, dynamic>{
      'wsfunction': wsFunction,
      'moodlewsrestformat': AppConstants.moodleRestFormat,
      ...?params,
    };

    try {
      final response = await _dio.post(
        '$baseUrl${AppConstants.moodleRestPath}',
        data: data,
      );

      return response.data;
    } on DioException catch (e) {
      if (e.error is MoodleException) throw e.error!;
      if (e.error is AuthException) throw e.error!;
      if (e.error is NetworkException) throw e.error!;
      if (e.error is ServerException) throw e.error!;
      throw ServerException(
        message: e.message ?? 'API call failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Upload a file to Moodle.
  ///
  /// Returns the draft item ID for the uploaded file.
  Future<List<dynamic>> uploadFile({
    required File file,
    required String fileArea,
    int itemId = 0,
  }) async {
    final baseUrl = await getBaseUrl();
    if (baseUrl == null) {
      throw const ServerException(message: 'Server URL not configured');
    }

    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token == null) {
      throw const AuthException(message: 'Not authenticated');
    }

    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'token': token,
      'filearea': fileArea,
      'itemid': itemId,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    try {
      final response = await _dio.post(
        '$baseUrl${AppConstants.moodleUploadPath}',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (response.data is List) {
        return response.data as List<dynamic>;
      }

      throw const ServerException(message: 'File upload failed');
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'File upload failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Download a file from Moodle.
  Future<String> downloadFile({
    required String fileUrl,
    required String savePath,
    void Function(int received, int total)? onProgress,
  }) async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    if (token == null) {
      throw const AuthException(message: 'Not authenticated');
    }

    final url = fileUrl.contains('?')
        ? '$fileUrl&token=$token'
        : '$fileUrl?token=$token';

    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
      );
      return savePath;
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Download failed',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Build a pluginfile URL with authentication token.
  Future<String> getPluginFileUrl(String relativePath) async {
    final baseUrl = await getBaseUrl();
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    return '$baseUrl${AppConstants.moodlePluginFilePath}$relativePath?token=$token';
  }

  /// Rewrite @@PLUGINFILE@@ URLs in HTML content.
  Future<String> rewritePluginFileUrls(
    String html, {
    required int contextId,
    required String component,
    required String fileArea,
    int itemId = 0,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await _secureStorage.read(key: AppConstants.tokenKey);

    return html.replaceAll(
      '@@PLUGINFILE@@',
      '$baseUrl${AppConstants.moodlePluginFilePath}/$contextId/$component/$fileArea/$itemId?token=$token',
    );
  }

  /// Logout: clear stored tokens.
  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.tokenKey);
    await _secureStorage.delete(key: AppConstants.privateTokenKey);
  }

  /// Check if user has a stored token.
  Future<bool> hasToken() async {
    final token = await _secureStorage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }
}
