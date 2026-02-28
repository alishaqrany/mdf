import '../../domain/entities/managed_user.dart';

class ManagedUserModel extends ManagedUser {
  const ManagedUserModel({
    required super.id,
    required super.username,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.email,
    super.profileImageUrl,
    super.department,
    super.institution,
    super.city,
    super.country,
    super.description,
    super.lang,
    super.suspended,
    super.confirmed,
    super.firstAccess,
    super.lastAccess,
    super.auth,
    super.roles,
  });

  factory ManagedUserModel.fromJson(Map<String, dynamic> json) {
    final roles = <UserRole>[];
    if (json['roles'] is List) {
      for (final r in json['roles'] as List) {
        if (r is Map<String, dynamic>) {
          roles.add(
            UserRole(
              roleId: r['roleid'] as int? ?? 0,
              shortName: r['shortname'] as String? ?? '',
              name: r['name'] as String? ?? '',
            ),
          );
        }
      }
    }

    final first = json['firstname'] as String? ?? '';
    final last = json['lastname'] as String? ?? '';
    final full = json['fullname'] as String? ?? '$first $last';

    return ManagedUserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      firstName: first,
      lastName: last,
      fullName: full,
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      department: json['department'] as String?,
      institution: json['institution'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      description: json['description'] as String?,
      lang: json['lang'] as String?,
      suspended: json['suspended'] == true || json['suspended'] == 1,
      confirmed: json['confirmed'] == true || json['confirmed'] == 1,
      firstAccess: json['firstaccess'] as int?,
      lastAccess: json['lastaccess'] as int?,
      auth: json['auth'] as String?,
      roles: roles,
    );
  }
}
