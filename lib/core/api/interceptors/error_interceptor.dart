import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../error/exceptions.dart';

/// Interceptor that handles Moodle API errors and converts them
/// to appropriate exceptions.
class ErrorInterceptor extends Interceptor {
  final Logger _logger = Logger();

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Moodle returns 200 even for errors, check the response body
    if (response.data is Map) {
      final data = response.data as Map;

      // Moodle error response format: {"exception": "...", "errorcode": "...", "message": "..."}
      if (data.containsKey('exception')) {
        final errorCode = data['errorcode'] as String?;
        final message = data['message'] as String? ?? 'Unknown Moodle error';
        final debugInfo = data['debuginfo'] as String?;

        _logger.e('Moodle API Error: $errorCode - $message');

        // Handle specific error codes
        if (errorCode == 'invalidtoken' || errorCode == 'invalidlogin') {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: AuthException(message: message),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }

        if (errorCode == 'accessexception') {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: MoodleException(
                message: message,
                errorCode: errorCode,
                debugInfo: debugInfo,
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }

        if (errorCode == 'requireloginerror') {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: AuthException(
                message: 'Session expired. Please login again.',
              ),
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        }

        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: MoodleException(
              message: message,
              errorCode: errorCode,
              debugInfo: debugInfo,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }

      // Check for token error response (from login/token.php)
      if (data.containsKey('error')) {
        final error = data['error'] as String? ?? 'Unknown error';
        final errorCode = data['errorcode'] as String?;

        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: ServerException(
              message: error,
              errorCode: errorCode,
              statusCode: response.statusCode,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // If already processed (has our custom error), forward it
    if (err.error is MoodleException ||
        err.error is AuthException ||
        err.error is ServerException) {
      handler.next(err);
      return;
    }

    // Handle network errors
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(message: 'Connection timed out'),
            type: err.type,
          ),
        );
        break;
      case DioExceptionType.connectionError:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(
              message: 'Could not connect to server',
            ),
            type: err.type,
          ),
        );
        break;
      default:
        handler.next(err);
    }
  }
}
