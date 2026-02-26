import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Logs all Moodle API requests and responses during development.
class LoggingInterceptor extends Interceptor {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final data = options.data is Map ? Map.from(options.data as Map) : {};
    // Hide token in logs
    if (data.containsKey('wstoken')) {
      data['wstoken'] = '***HIDDEN***';
    }
    _logger.i(
      '🌐 REQUEST[${options.method}] => PATH: ${options.path}\n'
      'FUNCTION: ${data['wsfunction'] ?? 'N/A'}\n'
      'DATA: $data',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final dataStr = response.data.toString();
    _logger.d(
      '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n'
      'DATA: ${dataStr.length > 500 ? '${dataStr.substring(0, 500)}...' : dataStr}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e(
      '❌ ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n'
      'MESSAGE: ${err.message}\n'
      'ERROR: ${err.error}',
    );
    handler.next(err);
  }
}
