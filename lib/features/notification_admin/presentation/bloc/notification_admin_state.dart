import 'package:equatable/equatable.dart';

abstract class NotificationAdminState extends Equatable {
  const NotificationAdminState();

  @override
  List<Object?> get props => [];
}

class NotificationAdminInitial extends NotificationAdminState {
  const NotificationAdminInitial();
}

class NotificationAdminLoading extends NotificationAdminState {
  const NotificationAdminLoading();
}

class UsersLoaded extends NotificationAdminState {
  final List<Map<String, dynamic>> users;
  final int total;

  const UsersLoaded({required this.users, required this.total});

  @override
  List<Object?> get props => [users, total];
}

class NotificationSent extends NotificationAdminState {
  final int totalSent;
  final int totalFailed;
  final String message;

  const NotificationSent({
    required this.totalSent,
    required this.totalFailed,
    required this.message,
  });

  @override
  List<Object?> get props => [totalSent, totalFailed, message];
}

class NotificationLogLoaded extends NotificationAdminState {
  final List<Map<String, dynamic>> logs;
  final int total;

  const NotificationLogLoaded({required this.logs, required this.total});

  @override
  List<Object?> get props => [logs, total];
}

class NotificationAdminError extends NotificationAdminState {
  final String message;

  const NotificationAdminError({required this.message});

  @override
  List<Object?> get props => [message];
}
