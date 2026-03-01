import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/core/error/exceptions.dart';

void main() {
  group('Failures', () {
    test('ServerFailure has correct message and code', () {
      const failure = ServerFailure(
        message: 'Internal server error',
        code: 500,
        errorCode: 'INTERNAL',
      );
      expect(failure.message, 'Internal server error');
      expect(failure.code, 500);
      expect(failure.errorCode, 'INTERNAL');
    });

    test('NetworkFailure has default message', () {
      const failure = NetworkFailure();
      expect(failure.message, 'No internet connection');
    });

    test('CacheFailure has default message', () {
      const failure = CacheFailure();
      expect(failure.message, 'Cache error');
    });

    test('AuthFailure has default message', () {
      const failure = AuthFailure();
      expect(failure.message, 'Authentication failed');
    });

    test('PermissionFailure has default message', () {
      const failure = PermissionFailure();
      expect(
        failure.message,
        'You do not have permission to perform this action',
      );
    });

    test('ValidationFailure with field errors', () {
      const failure = ValidationFailure(
        message: 'Validation failed',
        fieldErrors: {'email': 'Invalid email'},
      );
      expect(failure.fieldErrors?['email'], 'Invalid email');
    });

    test('UnexpectedFailure has default message', () {
      const failure = UnexpectedFailure();
      expect(failure.message, 'An unexpected error occurred');
    });

    test('Failures with matching props are equal', () {
      const a = ServerFailure(message: 'Error', code: 500);
      const b = ServerFailure(message: 'Error', code: 500);
      expect(a, equals(b));
    });

    test('Failures with different messages are not equal', () {
      const a = ServerFailure(message: 'Error A');
      const b = ServerFailure(message: 'Error B');
      expect(a, isNot(equals(b)));
    });
  });

  group('Exceptions', () {
    test('ServerException has correct properties', () {
      const e = ServerException(
        message: 'Server error',
        statusCode: 500,
        errorCode: 'ERR_INTERNAL',
      );
      expect(e.message, 'Server error');
      expect(e.statusCode, 500);
      expect(e.errorCode, 'ERR_INTERNAL');
    });

    test('NetworkException has message', () {
      const e = NetworkException(message: 'Timeout');
      expect(e.message, 'Timeout');
    });

    test('CacheException has message', () {
      const e = CacheException(message: 'Cache miss');
      expect(e.message, 'Cache miss');
    });

    test('AuthException has message', () {
      const e = AuthException(message: 'Token expired');
      expect(e.message, 'Token expired');
    });

    test('MoodleException has message and optional fields', () {
      const e = MoodleException(
        message: 'Invalid token',
        errorCode: 'invalidtoken',
        debugInfo: 'Token expired at ...',
      );
      expect(e.message, 'Invalid token');
      expect(e.errorCode, 'invalidtoken');
      expect(e.debugInfo, 'Token expired at ...');
    });
  });
}
