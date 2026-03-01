/// Single period entry from local_mdf_api_get_enrollment_stats.
class EnrollmentPeriodModel {
  final String label;
  final int newEnrollments;
  final int completions;
  final int newUsers;

  const EnrollmentPeriodModel({
    required this.label,
    required this.newEnrollments,
    required this.completions,
    required this.newUsers,
  });

  factory EnrollmentPeriodModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentPeriodModel(
      label: json['label'] as String? ?? '',
      newEnrollments: json['new_enrollments'] as int? ?? 0,
      completions: json['completions'] as int? ?? 0,
      newUsers: json['new_users'] as int? ?? 0,
    );
  }
}

/// Full enrollment stats response including periods + summary.
class EnrollmentStatsModel {
  final List<EnrollmentPeriodModel> periods;
  final int totalEnrollments;
  final int totalCompletions;
  final int totalNewUsers;
  final String periodType;
  final int monthsCovered;

  const EnrollmentStatsModel({
    required this.periods,
    required this.totalEnrollments,
    required this.totalCompletions,
    required this.totalNewUsers,
    required this.periodType,
    required this.monthsCovered,
  });

  factory EnrollmentStatsModel.fromJson(Map<String, dynamic> json) {
    final periodsList =
        (json['periods'] as List<dynamic>?)
            ?.map(
              (e) => EnrollmentPeriodModel.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        [];
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    return EnrollmentStatsModel(
      periods: periodsList,
      totalEnrollments: summary['total_enrollments'] as int? ?? 0,
      totalCompletions: summary['total_completions'] as int? ?? 0,
      totalNewUsers: summary['total_new_users'] as int? ?? 0,
      periodType: summary['period_type'] as String? ?? 'month',
      monthsCovered: summary['months_covered'] as int? ?? 6,
    );
  }
}
