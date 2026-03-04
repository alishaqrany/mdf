part of 'student_dashboard_bloc.dart';

abstract class StudentDashboardState extends Equatable {
  const StudentDashboardState();
  @override
  List<Object?> get props => [];
}

class StudentDashboardInitial extends StudentDashboardState {}

class StudentDashboardLoading extends StudentDashboardState {}

class StudentDashboardLoaded extends StudentDashboardState {
  final List<Course> enrolledCourses;
  final List<Course> recentCourses;
  final List<Course> inProgressCourses;
  final List<Course> completedCourses;
  final int totalEnrolled;
  final int totalCompleted;
  final int totalInProgress;
  final List<CalendarEvent> upcomingEvents;
  final List<Course> recommendedCourses;

  const StudentDashboardLoaded({
    required this.enrolledCourses,
    required this.recentCourses,
    required this.inProgressCourses,
    required this.completedCourses,
    required this.totalEnrolled,
    required this.totalCompleted,
    required this.totalInProgress,
    this.upcomingEvents = const [],
    this.recommendedCourses = const [],
  });

  @override
  List<Object?> get props => [
    enrolledCourses,
    recentCourses,
    inProgressCourses,
    completedCourses,
    totalEnrolled,
    totalCompleted,
    totalInProgress,
    upcomingEvents,
    recommendedCourses,
  ];
}

class StudentDashboardError extends StudentDashboardState {
  final String message;
  const StudentDashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
