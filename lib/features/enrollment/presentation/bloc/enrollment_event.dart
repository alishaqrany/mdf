import 'package:equatable/equatable.dart';

abstract class EnrollmentEvent extends Equatable {
  const EnrollmentEvent();

  @override
  List<Object?> get props => [];
}

/// Load enrolled users for a course.
class LoadEnrolledUsers extends EnrollmentEvent {
  final int courseId;

  const LoadEnrolledUsers({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Enrol a single user in a course.
class EnrollUser extends EnrollmentEvent {
  final int courseId;
  final int userId;
  final int roleId;

  const EnrollUser({
    required this.courseId,
    required this.userId,
    required this.roleId,
  });

  @override
  List<Object?> get props => [courseId, userId, roleId];
}

/// Bulk enrol multiple users.
class BulkEnrollUsers extends EnrollmentEvent {
  final int courseId;
  final List<int> userIds;
  final int roleId;

  const BulkEnrollUsers({
    required this.courseId,
    required this.userIds,
    required this.roleId,
  });

  @override
  List<Object?> get props => [courseId, userIds, roleId];
}

/// Unenrol a user from a course.
class UnenrollUser extends EnrollmentEvent {
  final int courseId;
  final int userId;

  const UnenrollUser({required this.courseId, required this.userId});

  @override
  List<Object?> get props => [courseId, userId];
}
