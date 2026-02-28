import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/enrolled_user.dart';

/// Abstract repository for enrollment management.
abstract class EnrollmentRepository {
  /// Get all users enrolled in a course.
  Future<Either<Failure, List<EnrolledUser>>> getEnrolledUsers(int courseId);

  /// Enrol a single user in a course with a specific role.
  Future<Either<Failure, void>> enrollUser({
    required int courseId,
    required int userId,
    required int roleId,
  });

  /// Bulk enrol multiple users in a course.
  Future<Either<Failure, void>> bulkEnrollUsers({
    required int courseId,
    required List<int> userIds,
    required int roleId,
  });

  /// Unenrol a user from a course.
  Future<Either<Failure, void>> unenrollUser({
    required int courseId,
    required int userId,
  });

  /// Assign a role to a user in a specific context.
  Future<Either<Failure, void>> assignRole({
    required int userId,
    required int roleId,
    required int contextId,
  });

  /// Unassign a role from a user in a specific context.
  Future<Either<Failure, void>> unassignRole({
    required int userId,
    required int roleId,
    required int contextId,
  });
}
