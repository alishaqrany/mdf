import 'package:equatable/equatable.dart';

/// Represents a user enrolled in a course.
class EnrolledUser extends Equatable {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final List<EnrolledRole> roles;
  final int? firstAccess;
  final int? lastAccess;

  const EnrolledUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
    this.roles = const [],
    this.firstAccess,
    this.lastAccess,
  });

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  String get primaryRoleName {
    if (roles.isEmpty) return 'student';
    return roles.first.shortName;
  }

  @override
  List<Object?> get props => [id, username, email, roles];
}

/// A role assigned to an enrolled user in a course.
class EnrolledRole extends Equatable {
  final int roleId;
  final String shortName;
  final String name;

  const EnrolledRole({
    required this.roleId,
    required this.shortName,
    required this.name,
  });

  @override
  List<Object?> get props => [roleId, shortName];
}

/// Available roles with known Moodle role IDs.
class MoodleRoles {
  MoodleRoles._();

  /// Default Moodle role IDs (may vary by installation)
  static const int manager = 1;
  static const int courseCreator = 2;
  static const int editingTeacher = 3;
  static const int teacher = 4;
  static const int student = 5;

  /// Mapping of role ID to short name
  static const Map<int, String> roleNames = {
    1: 'manager',
    2: 'coursecreator',
    3: 'editingteacher',
    4: 'teacher',
    5: 'student',
  };
}
