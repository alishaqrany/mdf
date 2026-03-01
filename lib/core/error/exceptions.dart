/// Base exception classes for the app
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ServerException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => 'ServerException: $message (code: $errorCode, status: $statusCode)';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException({this.message = 'No internet connection'});

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException({this.message = 'Cache error'});

  @override
  String toString() => 'CacheException: $message';
}

class AuthException implements Exception {
  final String message;

  const AuthException({this.message = 'Authentication failed'});

  @override
  String toString() => 'AuthException: $message';
}

class MoodleException implements Exception {
  final String message;
  final String? errorCode;
  final String? debugInfo;

  const MoodleException({
    required this.message,
    this.errorCode,
    this.debugInfo,
  });

  @override
  String toString() => 'MoodleException: $message (errorCode: $errorCode)';
}
