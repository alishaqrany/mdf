import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final MoodleApiClient apiClient;

  AdminDashboardBloc({required this.apiClient})
    : super(AdminDashboardInitial()) {
    on<LoadAdminDashboard>(_onLoad);
    on<RefreshAdminDashboard>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadAdminDashboard event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    await _loadDashboard(emit);
  }

  Future<void> _onRefresh(
    RefreshAdminDashboard event,
    Emitter<AdminDashboardState> emit,
  ) async {
    await _loadDashboard(emit);
  }

  Future<void> _loadDashboard(Emitter<AdminDashboardState> emit) async {
    try {
      // Get total courses
      final coursesResponse = await apiClient.call(
        MoodleApiEndpoints.getCourses,
      );
      final totalCourses = coursesResponse is List ? coursesResponse.length : 0;

      // Get users (basic search for count)
      int totalUsers = 0;
      try {
        final usersResponse = await apiClient.call(
          MoodleApiEndpoints.getUsers,
          params: {'criteria[0][key]': 'email', 'criteria[0][value]': '%'},
        );
        if (usersResponse is Map && usersResponse.containsKey('users')) {
          totalUsers = (usersResponse['users'] as List).length;
        }
      } catch (_) {
        // User search might fail for non-admin
      }

      emit(
        AdminDashboardLoaded(
          totalUsers: totalUsers,
          totalCourses: totalCourses,
          activeEnrollments: 0, // Would need custom API
          totalQuizzes: 0, // Would need counting from courses
        ),
      );
    } catch (e) {
      emit(AdminDashboardError(message: e.toString()));
    }
  }
}
