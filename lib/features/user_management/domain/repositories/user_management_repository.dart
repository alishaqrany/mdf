import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/managed_user.dart';

abstract class UserManagementRepository {
  /// Search/list users with optional criteria.
  Future<Either<Failure, List<ManagedUser>>> getUsers({
    String? search,
    String? role,
  });

  /// Get a single user by ID.
  Future<Either<Failure, ManagedUser>> getUserById(int userId);

  /// Create a new user.
  Future<Either<Failure, ManagedUser>> createUser({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    String? department,
    String? institution,
    String? city,
    String? country,
    String? lang,
  });

  /// Update an existing user.
  Future<Either<Failure, void>> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? department,
    String? institution,
    String? city,
    String? country,
    String? lang,
    bool? suspended,
  });

  /// Delete a user.
  Future<Either<Failure, void>> deleteUser(int userId);

  /// Reset a user's password.
  Future<Either<Failure, void>> resetPassword(int userId, String newPassword);

  /// Suspend or unsuspend a user.
  Future<Either<Failure, void>> toggleSuspend(int userId, bool suspend);
}
