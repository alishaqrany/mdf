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

  /// Rich data from MDF custom plugin (null if plugin not installed).
  final DashboardStatsModel? stats;
  final EnrollmentStatsModel? enrollmentStats;
  final SystemHealthModel? systemHealth;

  /// Whether the custom MDF plugin is available on the server.
  final bool pluginAvailable;

  const AdminDashboardLoaded({
    required this.totalUsers,
    required this.totalCourses,
    required this.activeEnrollments,
    required this.totalQuizzes,
    this.stats,
    this.enrollmentStats,
    this.systemHealth,
    this.pluginAvailable = false,
  });

  @override
  List<Object?> get props => [
    totalUsers,
    totalCourses,
    activeEnrollments,
    totalQuizzes,
    stats,
    enrollmentStats,
    systemHealth,
    pluginAvailable,
  ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;
  const AdminDashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
