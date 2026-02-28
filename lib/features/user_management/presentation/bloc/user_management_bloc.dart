import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/user_management_repository.dart';

part 'user_management_event.dart';
part 'user_management_state.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  final UserManagementRepository repository;

  UserManagementBloc({required this.repository})
    : super(UserManagementInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<SearchUsers>(_onSearchUsers);
    on<LoadUserDetail>(_onLoadUserDetail);
    on<CreateUser>(_onCreateUser);
    on<UpdateUser>(_onUpdateUser);
    on<DeleteUser>(_onDeleteUser);
    on<ResetUserPassword>(_onResetPassword);
    on<ToggleUserSuspension>(_onToggleSuspension);
  }

  Future<void> _onLoadUsers(
    LoadUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.getUsers(role: event.roleFilter);
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (users) => emit(UsersLoaded(users: users)),
    );
  }

  Future<void> _onSearchUsers(
    SearchUsers event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.getUsers(search: event.query);
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (users) => emit(UsersLoaded(users: users)),
    );
  }

  Future<void> _onLoadUserDetail(
    LoadUserDetail event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.getUserById(event.userId);
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (user) => emit(UserDetailLoaded(user: user)),
    );
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.createUser(
      username: event.username,
      password: event.password,
      firstName: event.firstName,
      lastName: event.lastName,
      email: event.email,
      department: event.department,
      institution: event.institution,
      city: event.city,
      country: event.country,
    );
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (user) => emit(UserCreated(user: user)),
    );
  }

  Future<void> _onUpdateUser(
    UpdateUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.updateUser(
      userId: event.userId,
      firstName: event.firstName,
      lastName: event.lastName,
      email: event.email,
      department: event.department,
      institution: event.institution,
      city: event.city,
      country: event.country,
      suspended: event.suspended,
    );
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (_) => emit(UserUpdated()),
    );
  }

  Future<void> _onDeleteUser(
    DeleteUser event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.deleteUser(event.userId);
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (_) => emit(UserDeleted()),
    );
  }

  Future<void> _onResetPassword(
    ResetUserPassword event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.resetPassword(
      event.userId,
      event.newPassword,
    );
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (_) => emit(PasswordReset()),
    );
  }

  Future<void> _onToggleSuspension(
    ToggleUserSuspension event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await repository.toggleSuspend(event.userId, event.suspend);
    result.fold(
      (f) => emit(UserManagementError(message: f.message)),
      (_) => emit(UserSuspensionToggled(suspended: event.suspend)),
    );
  }
}
