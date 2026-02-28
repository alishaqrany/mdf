import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../courses/domain/entities/course.dart';
import '../bloc/student_dashboard_bloc.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final authState = context.read<AuthBloc>().state;
        final userId = authState is AuthAuthenticated ? authState.user.id : 0;
        return sl<StudentDashboardBloc>()
          ..add(LoadStudentDashboard(userId: userId));
      },
      child: const _StudentDashboardView(),
    );
  }
}

class _StudentDashboardView extends StatelessWidget {
  const _StudentDashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      body: BlocBuilder<StudentDashboardBloc, StudentDashboardState>(
        builder: (context, state) {
          if (state is StudentDashboardLoading) {
            return const _DashboardShimmer();
          }

          if (state is StudentDashboardError) {
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
                      if (user != null) {
                        context.read<StudentDashboardBloc>().add(
                          LoadStudentDashboard(userId: user.id),
                        );
                      }
                    },
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is StudentDashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  context.read<StudentDashboardBloc>().add(
                    RefreshStudentDashboard(userId: user.id),
                  );
                }
              },
              child: CustomScrollView(
                slivers: [
                  // ─── Welcome Header ───
                  SliverToBoxAdapter(
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: _WelcomeHeader(
                        userName: user?.firstName ?? '',
                        profileImageUrl: user?.profileImageUrl,
                        userId: user?.id ?? 0,
                      ),
                    ),
                  ),

                  // ─── Stats Cards ───
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 100),
                      child: _StatsRow(
                        enrolled: state.totalEnrolled,
                        inProgress: state.totalInProgress,
                        completed: state.totalCompleted,
                      ),
                    ),
                  ),

                  // ─── Quick Access Grid ───
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 150),
                      child: _QuickAccessGrid(userId: user?.id ?? 0),
                    ),
                  ),

                  // ─── Continue Learning Section ───
                  if (state.recentCourses.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        child: _SectionHeader(
                          title: tr('dashboard.continue_learning'),
                          onViewAll: () => context.go('/student/courses'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 250),
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: state.recentCourses.length,
                            itemBuilder: (context, index) =>
                                _ContinueLearningCard(
                                  course: state.recentCourses[index],
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // ─── My Courses Section ───
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 300),
                      child: _SectionHeader(
                        title: tr('dashboard.my_courses'),
                        onViewAll: () => context.go('/student/courses'),
                      ),
                    ),
                  ),
                  if (state.enrolledCourses.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 80,
                              color: AppColors.textTertiaryLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('dashboard.no_courses'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => FadeInUp(
                            duration: const Duration(milliseconds: 400),
                            delay: Duration(milliseconds: 350 + (index * 50)),
                            child: _CourseListItem(
                              course: state.enrolledCourses[index],
                            ),
                          ),
                          childCount: state.enrolledCourses.length.clamp(0, 5),
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

// ─── Welcome Header ───
class _WelcomeHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final int userId;

  const _WelcomeHeader({
    required this.userName,
    this.profileImageUrl,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('dashboard.welcome'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Search icon
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => context.push('/student/search'),
          ),
          // Messages icon
          IconButton(
            icon: const Icon(Icons.mail_outline_rounded, color: Colors.white),
            tooltip: tr('common.messages'),
            onPressed: () => context.push('/student/messages'),
          ),
          // Notifications icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            tooltip: tr('common.notifications'),
            onPressed: () =>
                context.push('/student/notifications?userId=$userId'),
          ),
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            backgroundImage: profileImageUrl != null
                ? CachedNetworkImageProvider(profileImageUrl!)
                : null,
            child: profileImageUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ───
class _StatsRow extends StatelessWidget {
  final int enrolled;
  final int inProgress;
  final int completed;

  const _StatsRow({
    required this.enrolled,
    required this.inProgress,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.menu_book_rounded,
              label: tr('dashboard.enrolled_courses'),
              value: enrolled.toString(),
              color: AppColors.primary,
              bgColor: AppColors.primarySurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              label: tr('dashboard.in_progress'),
              value: inProgress.toString(),
              color: AppColors.warning,
              bgColor: AppColors.warningLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.check_circle_rounded,
              label: tr('dashboard.completed_courses'),
              value: completed.toString(),
              color: AppColors.success,
              bgColor: AppColors.successLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;

  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text(tr('dashboard.view_all')),
            ),
        ],
      ),
    );
  }
}

// ─── Quick Access Grid ───
class _QuickAccessGrid extends StatelessWidget {
  final int userId;

  const _QuickAccessGrid({required this.userId});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(
        Icons.assignment_rounded,
        tr('assignments.title'),
        AppColors.warning,
        () => context.push('/student/grades?userId=$userId'),
      ),
      _QuickItem(
        Icons.grade_rounded,
        tr('grades.title'),
        AppColors.success,
        () => context.push('/student/grades?userId=$userId'),
      ),
      _QuickItem(
        Icons.notifications_rounded,
        tr('notifications.title'),
        AppColors.info,
        () => context.push('/student/notifications?userId=$userId'),
      ),
      _QuickItem(
        Icons.search_rounded,
        tr('common.search'),
        AppColors.accent,
        () => context.push('/student/search'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(item.icon, color: item.color, size: 26),
                          const SizedBox(height: 6),
                          Text(
                            item.label,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: item.color,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickItem(this.icon, this.label, this.color, this.onTap);
}

// ─── Continue Learning Card ───
class _ContinueLearningCard extends StatelessWidget {
  final Course course;

  const _ContinueLearningCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (course.progress ?? 0) / 100;

    return Container(
      width: 280,
      margin: const EdgeInsetsDirectional.only(end: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            final imageParam = course.imageUrl != null
                ? '&image=${Uri.encodeComponent(course.imageUrl!)}'
                : '';
            context.push(
              '/student/course/${course.id}?title=${Uri.encodeComponent(course.fullName)}$imageParam',
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              SizedBox(
                height: 100,
                width: double.infinity,
                child: course.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: course.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.primarySurface,
                          child: const Center(
                            child: Icon(Icons.image, color: AppColors.primary),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primarySurface,
                          child: const Center(
                            child: Icon(Icons.school, color: AppColors.primary),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primarySurface,
                        child: const Center(
                          child: Icon(
                            Icons.school,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
              ),
              // Course Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.fullName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    LinearPercentIndicator(
                      lineHeight: 6,
                      percent: progress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.primarySurface,
                      progressColor: AppColors.primary,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                      trailing: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 8),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Course List Item ───
class _CourseListItem extends StatelessWidget {
  final Course course;

  const _CourseListItem({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (course.progress ?? 0) / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          final imageParam = course.imageUrl != null
              ? '&image=${Uri.encodeComponent(course.imageUrl!)}'
              : '';
          context.push(
            '/student/course/${course.id}?title=${Uri.encodeComponent(course.fullName)}$imageParam',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: course.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: course.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.primarySurface),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primarySurface,
                            child: const Icon(
                              Icons.school,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primarySurface,
                          child: const Icon(
                            Icons.school,
                            color: AppColors.primary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.fullName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.categoryName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.categoryName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    LinearPercentIndicator(
                      lineHeight: 5,
                      percent: progress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.primarySurface,
                      progressColor: progress >= 1.0
                          ? AppColors.success
                          : AppColors.primary,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Progress Badge
              CircularPercentIndicator(
                radius: 22,
                lineWidth: 3,
                percent: progress.clamp(0.0, 1.0),
                center: Text(
                  '${(progress * 100).toInt()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
                progressColor: progress >= 1.0
                    ? AppColors.success
                    : AppColors.primary,
                backgroundColor: AppColors.primarySurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer Loading ───
class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header shimmer
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Stats shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: List.generate(
                  3,
                  (_) => Expanded(
                    child: Container(
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Cards shimmer
            ...List.generate(
              4,
              (_) => Container(
                height: 90,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
