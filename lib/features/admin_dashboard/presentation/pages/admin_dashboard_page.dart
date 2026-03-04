import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../data/models/enrollment_stats_model.dart';
import '../bloc/admin_dashboard_bloc.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminDashboardBloc>()..add(const LoadAdminDashboard()),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView();

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  bool _hasMdfService = true;

  @override
  void initState() {
    super.initState();
    sl<MoodleApiClient>().hasMdfService().then((value) {
      if (mounted && !value) setState(() => _hasMdfService = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<AdminDashboardBloc, AdminDashboardState>(
        builder: (context, state) {
          if (state is AdminDashboardLoading) {
            return const _AdminShimmer();
          }

          if (state is AdminDashboardError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AdminDashboardBloc>().add(
                        const LoadAdminDashboard(),
                      );
                    },
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is AdminDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminDashboardBloc>().add(
                  const RefreshAdminDashboard(),
                );
              },
              child: CustomScrollView(
                slivers: [
                  // ─── Admin AppBar ───
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: Text(
                        tr('admin.dashboard'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                    ),
                  ),

                  // ─── Service Mode Warning ───
                  if (!_hasMdfService)
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'خدمة mdf_mobile غير متاحة. بعض الميزات قد لا تعمل.\n'
                                'اذهب إلى الملف الشخصي → إعادة مصادقة الخدمة.\n'
                                'mdf_mobile service unavailable. Some features may not work.\n'
                                'Go to Profile → Re-authenticate Service.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ─── Overview Stats ───
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              tr('admin.overview'),
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FadeInLeft(
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 100),
                                  child: _AdminStatCard(
                                    icon: Icons.people_rounded,
                                    label: tr('admin.total_users'),
                                    value: state.totalUsers.toString(),
                                    color: AppColors.primary,
                                    bgGradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF8B83FF),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FadeInRight(
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 100),
                                  child: _AdminStatCard(
                                    icon: Icons.school_rounded,
                                    label: tr('admin.total_courses'),
                                    value: state.totalCourses.toString(),
                                    color: AppColors.secondary,
                                    bgGradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF00BFA6),
                                        Color(0xFF4CD7C2),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FadeInLeft(
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 200),
                                  child: _AdminStatCard(
                                    icon: Icons.assignment_ind_rounded,
                                    label: tr('admin.active_enrollments'),
                                    value: state.activeEnrollments.toString(),
                                    color: AppColors.accent,
                                    bgGradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6B6B),
                                        Color(0xFFFF9191),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FadeInRight(
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 200),
                                  child: _AdminStatCard(
                                    icon: state.pluginAvailable
                                        ? Icons.circle
                                        : Icons.quiz_rounded,
                                    label: state.pluginAvailable
                                        ? tr('admin.online_users')
                                        : tr('admin.total_quizzes'),
                                    value: state.pluginAvailable
                                        ? (state.stats?.onlineUsers ?? 0)
                                              .toString()
                                        : state.totalQuizzes.toString(),
                                    color: AppColors.warning,
                                    bgGradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFB74D),
                                        Color(0xFFFFCC80),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ─── Plugin Extra Stats (Active Users, Completions) ───
                  if (state.pluginAvailable && state.stats != null)
                    SliverToBoxAdapter(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 250),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _MiniStatTile(
                                  icon: Icons.trending_up,
                                  label: tr('admin.active_users_30d'),
                                  value: state.stats!.activeUsers.toString(),
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MiniStatTile(
                                  icon: Icons.person_add_alt_1,
                                  label: tr('admin.new_users_month'),
                                  value: state.stats!.newUsersMonth.toString(),
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MiniStatTile(
                                  icon: Icons.check_circle_outline,
                                  label: tr('admin.completions_month'),
                                  value: state.stats!.completionsMonth
                                      .toString(),
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ─── Quick Actions ───
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 300),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Text(
                              tr('admin.quick_actions'),
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _QuickActionChip(
                                  icon: Icons.person_add_rounded,
                                  label: tr('admin.add_user'),
                                  onTap: () =>
                                      context.push('/admin/users/create'),
                                ),
                                _QuickActionChip(
                                  icon: Icons.add_box_rounded,
                                  label: tr('admin.create_course'),
                                  onTap: () =>
                                      context.push('/admin/courses/create'),
                                ),
                                _QuickActionChip(
                                  icon: Icons.group_add_rounded,
                                  label: tr('admin.manage_enrollments'),
                                  onTap: () =>
                                      context.push('/admin/enrollment'),
                                ),
                                _QuickActionChip(
                                  icon: Icons.people_rounded,
                                  label: tr('admin.user_management'),
                                  onTap: () => context.push('/admin/users'),
                                ),
                                _QuickActionChip(
                                  icon: Icons.bar_chart_rounded,
                                  label: tr('admin.view_reports'),
                                  onTap: () {},
                                ),
                                _QuickActionChip(
                                  icon: Icons.visibility_off_rounded,
                                  label: tr('admin.course_visibility'),
                                  onTap: () =>
                                      context.push('/admin/course-visibility'),
                                ),
                                _QuickActionChip(
                                  icon: Icons.groups_rounded,
                                  label: tr('admin.manage_cohorts'),
                                  onTap: () => context.push('/admin/cohorts'),
                                ),
                                _QuickActionChip(
                                  icon: Icons.smart_toy_rounded,
                                  label: tr('admin.ai_settings'),
                                  onTap: () =>
                                      context.push('/admin/ai-settings'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Enrollment Trend Chart (plugin only) ───
                  if (state.pluginAvailable &&
                      state.enrollmentStats != null &&
                      state.enrollmentStats!.periods.isNotEmpty)
                    SliverToBoxAdapter(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 400),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('admin.enrollment_trends'),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 220,
                                    child: _EnrollmentLineChart(
                                      stats: state.enrollmentStats!,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ─── System Health (plugin only) ───
                  if (state.pluginAvailable && state.systemHealth != null)
                    SliverToBoxAdapter(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 450),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('admin.system_health'),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  _HealthRow(
                                    label: 'Moodle',
                                    value: state.systemHealth!.moodleVersion,
                                  ),
                                  _HealthRow(
                                    label: 'PHP',
                                    value: state.systemHealth!.phpVersion,
                                  ),
                                  _HealthRow(
                                    label: tr('admin.database'),
                                    value:
                                        '${state.systemHealth!.dbType} — ${_formatBytes(state.systemHealth!.dbSizeBytes)}',
                                  ),
                                  _HealthRow(
                                    label: tr('admin.disk_usage'),
                                    value: _formatBytes(
                                      state.systemHealth!.datarootSizeBytes,
                                    ),
                                  ),
                                  _HealthRow(
                                    label: tr('admin.disk_free'),
                                    value: _formatBytes(
                                      state.systemHealth!.freeDiskBytes,
                                    ),
                                  ),
                                  _HealthRow(
                                    label: 'Cron',
                                    value: state.systemHealth!.cronOverdue
                                        ? tr('admin.cron_overdue')
                                        : tr('admin.cron_ok'),
                                    valueColor: state.systemHealth!.cronOverdue
                                        ? AppColors.error
                                        : Colors.green,
                                  ),
                                  _HealthRow(
                                    label: tr('admin.pending_tasks'),
                                    value: state.systemHealth!.pendingAdhocTasks
                                        .toString(),
                                  ),
                                  _HealthRow(
                                    label: tr('admin.failed_tasks'),
                                    value: state.systemHealth!.failedTasks24h
                                        .toString(),
                                    valueColor:
                                        state.systemHealth!.failedTasks24h > 0
                                        ? AppColors.error
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ─── Pie Chart (fallback overview) ───
                  if (!state.pluginAvailable)
                    SliverToBoxAdapter(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 400),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('admin.system_overview'),
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    height: 200,
                                    child: _OverviewPieChart(
                                      users: state.totalUsers,
                                      courses: state.totalCourses,
                                      enrollments: state.activeEnrollments,
                                      quizzes: state.totalQuizzes,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

// ─── Admin Stat Card ───
class _AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final LinearGradient bgGradient;

  const _AdminStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgGradient,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Chip ───
class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

// ─── Pie Chart ───
class _OverviewPieChart extends StatelessWidget {
  final int users;
  final int courses;
  final int enrollments;
  final int quizzes;

  const _OverviewPieChart({
    required this.users,
    required this.courses,
    required this.enrollments,
    required this.quizzes,
  });

  @override
  Widget build(BuildContext context) {
    final total = (users + courses + enrollments + quizzes).toDouble();
    if (total == 0) {
      return const Center(child: Text('No data'));
    }

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: users.toDouble(),
                  color: AppColors.primary,
                  radius: 40,
                  title: '',
                ),
                PieChartSectionData(
                  value: courses.toDouble(),
                  color: AppColors.secondary,
                  radius: 40,
                  title: '',
                ),
                PieChartSectionData(
                  value: enrollments.toDouble(),
                  color: AppColors.accent,
                  radius: 40,
                  title: '',
                ),
                PieChartSectionData(
                  value: quizzes.toDouble(),
                  color: AppColors.warning,
                  radius: 40,
                  title: '',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LegendItem(
              color: AppColors.primary,
              label: tr('admin.total_users'),
              value: users.toString(),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: AppColors.secondary,
              label: tr('admin.total_courses'),
              value: courses.toString(),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: AppColors.accent,
              label: tr('admin.active_enrollments'),
              value: enrollments.toString(),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              color: AppColors.warning,
              label: tr('admin.total_quizzes'),
              value: quizzes.toString(),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text('$label: $value', style: theme.textTheme.bodySmall),
      ],
    );
  }
}

// ─── Mini Stat Tile (compact stat for plugin data) ───
class _MiniStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Enrollment Line Chart ───
class _EnrollmentLineChart extends StatelessWidget {
  final EnrollmentStatsModel stats;

  const _EnrollmentLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.periods.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final enrollSpots = <FlSpot>[];
    final completionSpots = <FlSpot>[];
    for (int i = 0; i < stats.periods.length; i++) {
      enrollSpots.add(
        FlSpot(i.toDouble(), stats.periods[i].newEnrollments.toDouble()),
      );
      completionSpots.add(
        FlSpot(i.toDouble(), stats.periods[i].completions.toDouble()),
      );
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= stats.periods.length) {
                  return const SizedBox();
                }
                final label = stats.periods[idx].label;
                // Show short label (last 5 chars, e.g. "05-25")
                return Text(
                  label.length > 5 ? label.substring(5) : label,
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: enrollSpots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: completionSpots,
            isCurved: true,
            color: AppColors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.secondary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Health Row ───
class _HealthRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HealthRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Format bytes to human-readable string.
String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  int idx = 0;
  double size = bytes.toDouble();
  while (size >= 1024 && idx < units.length - 1) {
    size /= 1024;
    idx++;
  }
  return '${size.toStringAsFixed(1)} ${units[idx]}';
}

// ─── Shimmer ───
class _AdminShimmer extends StatelessWidget {
  const _AdminShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(height: 120, color: Colors.white),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
