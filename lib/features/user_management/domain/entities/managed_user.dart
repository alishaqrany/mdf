import 'package:equatable/equatable.dart';

/// Represents a Moodle user with full admin-visible fields.
class ManagedUser extends Equatable {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final String? department;
  final String? institution;
  final String? city;
  final String? country;
  final String? description;
  final String? lang;
  final bool suspended;
  final bool confirmed;
  final int? firstAccess;
  final int? lastAccess;
  final String? auth;
  final List<UserRole> roles;

  const ManagedUser({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
    this.department,
    this.institution,
    this.city,
    this.country,
    this.description,
    this.lang,
    this.suspended = false,
    this.confirmed = true,
    this.firstAccess,
    this.lastAccess,
    this.auth,
    this.roles = const [],
  });

  String get displayName =>
      fullName.isNotEmpty ? fullName : '$firstName $lastName';

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  bool get isActive => !suspended && confirmed;

  String get primaryRole {
    if (roles.isEmpty) return 'user';
    // Priority: manager > editingteacher > teacher > student
    const priority = ['manager', 'editingteacher', 'teacher', 'student'];
    for (final p in priority) {
      if (roles.any((r) => r.shortName == p)) return p;
    }
    return roles.first.shortName;
  }

  DateTime? get lastAccessDate => lastAccess != null && lastAccess! > 0
      ? DateTime.fromMillisecondsSinceEpoch(lastAccess! * 1000)
      : null;

  @override
  List<Object?> get props => [id, username, email];
}

/// A role assigned to a user.
class UserRole extends Equatable {
  final int roleId;
  final String shortName;
  final String name;

  const UserRole({
    required this.roleId,
    required this.shortName,
    required this.name,
  });

  @override
  List<Object?> get props => [roleId, shortName];
}
