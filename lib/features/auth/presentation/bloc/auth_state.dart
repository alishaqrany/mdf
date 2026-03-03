part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class AuthInitial extends AuthState {}

/// Loading (checking auth or logging in).
class AuthLoading extends AuthState {}

/// User is authenticated.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {}

/// Authentication error.
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Token is being refreshed.
class AuthRefreshing extends AuthState {}

/// Token refresh failed.
class AuthRefreshError extends AuthState {
  final String message;

  const AuthRefreshError({required this.message});

  @override
  List<Object?> get props => [message];
}
