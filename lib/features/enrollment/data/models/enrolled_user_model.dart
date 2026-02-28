import '../../domain/entities/enrolled_user.dart';

class EnrolledUserModel extends EnrolledUser {
  const EnrolledUserModel({
    required super.id,
    required super.username,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.email,
    super.profileImageUrl,
    super.roles,
    super.firstAccess,
    super.lastAccess,
  });

  factory EnrolledUserModel.fromJson(Map<String, dynamic> json) {
    final rolesList = <EnrolledRole>[];
    if (json['roles'] != null && json['roles'] is List) {
      for (final r in json['roles']) {
        rolesList.add(
          EnrolledRole(
            roleId: r['roleid'] ?? 0,
            shortName: r['shortname'] ?? '',
            name: r['name'] ?? '',
          ),
        );
      }
    }

    return EnrolledUserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      fullName:
          json['fullname'] ??
          '${json['firstname'] ?? ''} ${json['lastname'] ?? ''}'.trim(),
      email: json['email'] ?? '',
      profileImageUrl: json['profileimageurl'],
      roles: rolesList,
      firstAccess: json['firstaccess'],
      lastAccess: json['lastaccess'],
    );
  }
}
