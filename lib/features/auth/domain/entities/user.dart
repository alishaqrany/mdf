import 'package:equatable/equatable.dart';

/// Represents an authenticated user in the app.
class User extends Equatable {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? profileImageUrl;
  final String? lang;
  final bool isSiteAdmin;
  final bool isTeacher;
  final List<int> teacherCourseIds;
  final int? siteId;
  final String? siteName;
  final String? siteUrl;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.profileImageUrl,
    this.lang,
    this.isSiteAdmin = false,
    this.isTeacher = false,
    this.teacherCourseIds = const [],
    this.siteId,
    this.siteName,
    this.siteUrl,
  });

  /// User's display name.
  String get displayName =>
      fullName.isNotEmpty ? fullName : '$firstName $lastName';

  /// User's initials for avatar placeholder.
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Whether the user is an admin or manager.
  bool get isAdmin => isSiteAdmin;

  /// Whether the user has teacher role in a specific course.
  bool isTeacherInCourse(int courseId) =>
      isSiteAdmin || teacherCourseIds.contains(courseId);

  /// Copy with updated teacher info.
  User copyWithTeacherInfo({bool? isTeacher, List<int>? teacherCourseIds}) {
    return User(
      id: id,
      username: username,
      firstName: firstName,
      lastName: lastName,
      fullName: fullName,
      email: email,
      profileImageUrl: profileImageUrl,
      lang: lang,
      isSiteAdmin: isSiteAdmin,
      isTeacher: isTeacher ?? this.isTeacher,
      teacherCourseIds: teacherCourseIds ?? this.teacherCourseIds,
      siteId: siteId,
      siteName: siteName,
      siteUrl: siteUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    username,
    firstName,
    lastName,
    fullName,
    email,
    profileImageUrl,
    lang,
    isSiteAdmin,
    isTeacher,
    teacherCourseIds,
    siteId,
    siteName,
    siteUrl,
  ];
}
