import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Auth repository contract.
abstract class AuthRepository {
  /// Login with server URL, username, and password.
  Future<Either<Failure, User>> login({
    required String serverUrl,
    required String username,
    required String password,
  });

  /// Logout and clear session.
  Future<Either<Failure, void>> logout();

  /// Check if user is authenticated and return cached user.
  Future<Either<Failure, User>> checkAuth();

  /// Get current user from cache.
  Future<User?> getCachedUser();
}
