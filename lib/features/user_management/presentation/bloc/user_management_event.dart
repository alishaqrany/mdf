part of 'user_management_bloc.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();
  @override
  List<Object?> get props => [];
}

class LoadUsers extends UserManagementEvent {
  final String? roleFilter;
  const LoadUsers({this.roleFilter});
  @override
  List<Object?> get props => [roleFilter];
}

class SearchUsers extends UserManagementEvent {
  final String query;
  const SearchUsers({required this.query});
  @override
  List<Object?> get props => [query];
}

class LoadUserDetail extends UserManagementEvent {
  final int userId;
  const LoadUserDetail({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class CreateUser extends UserManagementEvent {
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final String email;
  final String? department;
  final String? institution;
  final String? city;
  final String? country;

  const CreateUser({
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.department,
    this.institution,
    this.city,
    this.country,
  });
  @override
  List<Object?> get props => [username, email];
}

class UpdateUser extends UserManagementEvent {
  final int userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? department;
  final String? institution;
  final String? city;
  final String? country;
  final bool? suspended;

  const UpdateUser({
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.department,
    this.institution,
    this.city,
    this.country,
    this.suspended,
  });
  @override
  List<Object?> get props => [userId];
}

class DeleteUser extends UserManagementEvent {
  final int userId;
  const DeleteUser({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class ResetUserPassword extends UserManagementEvent {
  final int userId;
  final String newPassword;
  const ResetUserPassword({required this.userId, required this.newPassword});
  @override
  List<Object?> get props => [userId];
}

class ToggleUserSuspension extends UserManagementEvent {
  final int userId;
  final bool suspend;
  const ToggleUserSuspension({required this.userId, required this.suspend});
  @override
  List<Object?> get props => [userId, suspend];
}
