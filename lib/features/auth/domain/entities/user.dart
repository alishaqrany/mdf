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
    this.siteId,
    this.siteName,
    this.siteUrl,
  });

  /// User's display name.
  String get displayName => fullName.isNotEmpty ? fullName : '$firstName $lastName';

  /// User's initials for avatar placeholder.
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// Whether the user is an admin or manager.
  bool get isAdmin => isSiteAdmin;

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
        siteId,
        siteName,
        siteUrl,
      ];
}
