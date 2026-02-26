part of 'admin_dashboard_bloc.dart';

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadAdminDashboard extends AdminDashboardEvent {
  const LoadAdminDashboard();
}

class RefreshAdminDashboard extends AdminDashboardEvent {
  const RefreshAdminDashboard();
}
