part of 'user_management_bloc.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();
  @override
  List<Object?> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UsersLoaded extends UserManagementState {
  final List<ManagedUser> users;
  const UsersLoaded({required this.users});
  @override
  List<Object?> get props => [users];
}

class UserDetailLoaded extends UserManagementState {
  final ManagedUser user;
  const UserDetailLoaded({required this.user});
  @override
  List<Object?> get props => [user];
}

class UserCreated extends UserManagementState {
  final ManagedUser user;
  const UserCreated({required this.user});
  @override
  List<Object?> get props => [user];
}

class UserUpdated extends UserManagementState {}

class UserDeleted extends UserManagementState {}

class PasswordReset extends UserManagementState {}

class UserSuspensionToggled extends UserManagementState {
  final bool suspended;
  const UserSuspensionToggled({required this.suspended});
  @override
  List<Object?> get props => [suspended];
}

class UserManagementError extends UserManagementState {
  final String message;
  const UserManagementError({required this.message});
  @override
  List<Object?> get props => [message];
}
