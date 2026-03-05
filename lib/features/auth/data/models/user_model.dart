import 'dart:convert';
import '../../domain/entities/user.dart';

/// User data model with JSON serialization for Moodle API responses.
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.firstName,
    required super.lastName,
    required super.fullName,
    required super.email,
    super.profileImageUrl,
    super.lang,
    super.isSiteAdmin,
    super.isTeacher,
    super.teacherCourseIds,
    super.siteId,
    super.siteName,
    super.siteUrl,
  });

  /// Create from Moodle `core_webservice_get_site_info` response.
  factory UserModel.fromSiteInfo(Map<String, dynamic> json) {
    return UserModel(
      id: json['userid'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      fullName: json['fullname'] as String? ?? '',
      email: json['useremail'] as String? ?? '',
      profileImageUrl: json['userpictureurl'] as String?,
      lang: json['lang'] as String?,
      isSiteAdmin: json['userissiteadmin'] as bool? ?? false,
      siteId: json['siteid'] as int?,
      siteName: json['sitename'] as String?,
      siteUrl: json['siteurl'] as String?,
    );
  }

  /// Create from Moodle user object (e.g., from core_user_get_users).
  factory UserModel.fromUserData(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['firstname'] as String? ?? '',
      lastName: json['lastname'] as String? ?? '',
      fullName: json['fullname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      lang: json['lang'] as String?,
    );
  }

  /// Serialize to JSON for local storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'lang': lang,
      'isSiteAdmin': isSiteAdmin,
      'isTeacher': isTeacher,
      'teacherCourseIds': teacherCourseIds,
      'siteId': siteId,
      'siteName': siteName,
      'siteUrl': siteUrl,
    };
  }

  /// Deserialize from local storage JSON.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImageUrl: json['profileImageUrl'] as String?,
      lang: json['lang'] as String?,
      isSiteAdmin: json['isSiteAdmin'] as bool? ?? false,
      isTeacher: json['isTeacher'] as bool? ?? false,
      teacherCourseIds:
          (json['teacherCourseIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      siteId: json['siteId'] as int?,
      siteName: json['siteName'] as String?,
      siteUrl: json['siteUrl'] as String?,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  factory UserModel.fromJsonString(String jsonString) {
    return UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
