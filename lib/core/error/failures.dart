import 'package:equatable/equatable.dart';

/// Base failure class for the app
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server-side failures (Moodle API errors)
class ServerFailure extends Failure {
  final String? errorCode;

  const ServerFailure({
    required super.message,
    super.code,
    this.errorCode,
  });
}

/// Network failures (no connection, timeout, etc.)
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection'});
}

/// Cache/local storage failures
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error'});
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Authentication failed',
    super.code,
  });
}

/// Permission failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    super.message = 'You do not have permission to perform this action',
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure({
    required super.message,
    this.fieldErrors,
  });
}

/// Unknown/unexpected failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({super.message = 'An unexpected error occurred'});
}
