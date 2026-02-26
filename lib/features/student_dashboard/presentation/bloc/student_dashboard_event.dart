part of 'student_dashboard_bloc.dart';

abstract class StudentDashboardEvent extends Equatable {
  const StudentDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadStudentDashboard extends StudentDashboardEvent {
  final int userId;
  const LoadStudentDashboard({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class RefreshStudentDashboard extends StudentDashboardEvent {
  final int userId;
  const RefreshStudentDashboard({required this.userId});
  @override
  List<Object?> get props => [userId];
}
