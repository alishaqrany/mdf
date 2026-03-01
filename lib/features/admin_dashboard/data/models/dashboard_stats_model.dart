/// Dashboard statistics returned by local_mdf_api_get_dashboard_stats.
class DashboardStatsModel {
  final int totalUsers;
  final int activeUsers;
  final int onlineUsers;
  final int totalCourses;
  final int totalEnrollments;
  final int newUsersMonth;
  final int newUsersWeek;
  final int completionsMonth;
  final double avgProgress;
  final int totalCategories;
  final int diskUsageBytes;

  const DashboardStatsModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.onlineUsers,
    required this.totalCourses,
    required this.totalEnrollments,
    required this.newUsersMonth,
    required this.newUsersWeek,
    required this.completionsMonth,
    required this.avgProgress,
    required this.totalCategories,
    required this.diskUsageBytes,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      onlineUsers: json['online_users'] as int? ?? 0,
      totalCourses: json['total_courses'] as int? ?? 0,
      totalEnrollments: json['total_enrollments'] as int? ?? 0,
      newUsersMonth: json['new_users_month'] as int? ?? 0,
      newUsersWeek: json['new_users_week'] as int? ?? 0,
      completionsMonth: json['completions_month'] as int? ?? 0,
      avgProgress: (json['avg_progress'] as num?)?.toDouble() ?? 0.0,
      totalCategories: json['total_categories'] as int? ?? 0,
      diskUsageBytes: json['disk_usage_bytes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_users': totalUsers,
    'active_users': activeUsers,
    'online_users': onlineUsers,
    'total_courses': totalCourses,
    'total_enrollments': totalEnrollments,
    'new_users_month': newUsersMonth,
    'new_users_week': newUsersWeek,
    'completions_month': completionsMonth,
    'avg_progress': avgProgress,
    'total_categories': totalCategories,
    'disk_usage_bytes': diskUsageBytes,
  };
}
