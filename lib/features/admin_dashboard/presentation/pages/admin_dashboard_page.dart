import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
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

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

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
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
                                    icon: Icons.quiz_rounded,
                                    label: tr('admin.total_quizzes'),
                                    value: state.totalQuizzes.toString(),
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
                                  onTap: () {},
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ─── Chart Section ───
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
