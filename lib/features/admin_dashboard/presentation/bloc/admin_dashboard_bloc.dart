import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/models/dashboard_stats_model.dart';
import '../../data/models/enrollment_stats_model.dart';
import '../../data/models/system_health_model.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final MoodleApiClient apiClient;
  late final AdminRemoteDataSource _adminDataSource;

  AdminDashboardBloc({required this.apiClient})
    : super(AdminDashboardInitial()) {
    _adminDataSource = AdminRemoteDataSourceImpl(apiClient: apiClient);
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
      // ── Try the custom MDF plugin endpoints first ──
      DashboardStatsModel? stats;
      EnrollmentStatsModel? enrollmentStats;
      SystemHealthModel? health;

      try {
        stats = await _adminDataSource.getDashboardStats();
      } catch (_) {
        // Plugin not installed — fall back to core APIs below.
      }

      if (stats != null) {
        // Plugin is available — fetch supporting data in parallel.
        final futures = await Future.wait([
          _adminDataSource
              .getEnrollmentStats()
              .then<EnrollmentStatsModel?>((v) => v)
              .catchError((_) => null as EnrollmentStatsModel?),
          _adminDataSource
              .getSystemHealth()
              .then<SystemHealthModel?>((v) => v)
              .catchError((_) => null as SystemHealthModel?),
        ]);

        enrollmentStats = futures[0] as EnrollmentStatsModel?;
        health = futures[1] as SystemHealthModel?;

        emit(
          AdminDashboardLoaded(
            totalUsers: stats.totalUsers,
            totalCourses: stats.totalCourses,
            activeEnrollments: stats.totalEnrollments,
            totalQuizzes: 0,
            stats: stats,
            enrollmentStats: enrollmentStats,
            systemHealth: health,
            pluginAvailable: true,
          ),
        );
        return;
      }

      // ── Fallback: core Moodle APIs (plugin not installed) ──
      int totalCourses = 0;
      try {
        final coursesResponse = await apiClient.call(
          MoodleApiEndpoints.getCourses,
        );
        totalCourses = coursesResponse is List ? coursesResponse.length : 0;
      } catch (_) {
        final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
        final userId = (siteInfo as Map<String, dynamic>)['userid'] as int?;
        if (userId != null) {
          final enrolledCourses = await apiClient.call(
            MoodleApiEndpoints.getUsersCourses,
            params: {'userid': userId},
          );
          totalCourses = enrolledCourses is List ? enrolledCourses.length : 0;
        }
      }

      int totalUsers = 0;
      try {
        final usersResponse = await apiClient.call(
          MoodleApiEndpoints.getUsers,
          params: {'criteria[0][key]': 'email', 'criteria[0][value]': '%'},
        );
        if (usersResponse is Map && usersResponse.containsKey('users')) {
          totalUsers = (usersResponse['users'] as List).length;
        }
      } catch (_) {}

      emit(
        AdminDashboardLoaded(
          totalUsers: totalUsers,
          totalCourses: totalCourses,
          activeEnrollments: 0,
          totalQuizzes: 0,
          pluginAvailable: false,
        ),
      );
    } catch (e) {
      emit(AdminDashboardError(message: e.toString()));
    }
  }
}
