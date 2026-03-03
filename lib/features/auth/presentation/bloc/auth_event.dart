part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is already authenticated (app startup).
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Login with credentials.
class AuthLoginRequested extends AuthEvent {
  final String serverUrl;
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [serverUrl, username, password];
}

/// Logout.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Refresh token (re-authenticate without logout).
class AuthRefreshTokenRequested extends AuthEvent {
  final String password;

  const AuthRefreshTokenRequested({required this.password});

  @override
  List<Object?> get props => [password];
}
