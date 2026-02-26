part of 'admin_dashboard_bloc.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();
  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final int totalUsers;
  final int totalCourses;
  final int activeEnrollments;
  final int totalQuizzes;

  const AdminDashboardLoaded({
    required this.totalUsers,
    required this.totalCourses,
    required this.activeEnrollments,
    required this.totalQuizzes,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalCourses,
    activeEnrollments,
    totalQuizzes,
  ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
