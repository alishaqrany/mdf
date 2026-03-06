import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../calendar/domain/entities/calendar_event.dart';
import '../../../ai/presentation/bloc/ai_insights_bloc.dart';
import '../bloc/student_dashboard_bloc.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<StudentDashboardBloc>()
                ..add(LoadStudentDashboard(userId: userId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<AiInsightsBloc>()..add(LoadStudentInsights(userId: userId)),
        ),
      ],
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

    // Detect whether user is an admin viewing the student dashboard
    final isAdminPreview = user != null && user.isAdmin;

    return PopScope(
      canPop: !isAdminPreview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isAdminPreview) {
          context.go('/admin');
        }
      },
      child: Scaffold(
      floatingActionButton: FadeInUp(
        duration: const Duration(milliseconds: 600),
        delay: const Duration(milliseconds: 500),
        child: FloatingActionButton.extended(
          heroTag: 'ai_chat_fab',
          onPressed: () => context.push('/student/ai-chat'),
          icon: const Icon(Icons.auto_awesome_rounded),
          label: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              tr('ai.ask_ai'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
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
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
            final isWide = ResponsiveLayout.isWide(context);
            final gridCols = ResponsiveLayout.gridColumns(context);

            return RefreshIndicator(
              onRefresh: () async {
                if (user != null) {
                  context.read<StudentDashboardBloc>().add(
                    RefreshStudentDashboard(userId: user.id),
                  );
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveLayout.contentMaxWidth(context),
                  ),
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

                      // ─── Upcoming Events ───
                      if (state.upcomingEvents.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 160),
                            child: _SectionHeader(
                              title: tr('dashboard.upcoming_events'),
                              onViewAll: () =>
                                  context.go('/student/calendar'),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 500),
                            delay: const Duration(milliseconds: 170),
                            child: _UpcomingEventsPreview(
                              events: state.upcomingEvents,
                            ),
                          ),
                        ),
                      ],

                      // ─── AI Insights Preview ───
                      SliverToBoxAdapter(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 175),
                          child: _AiInsightsPreview(userId: user?.id ?? 0),
                        ),
                      ),

                      // ─── Social Learning Preview ───
                      SliverToBoxAdapter(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 185),
                          child: const _SocialLearningPreview(),
                        ),
                      ),

                      // ─── Gamification Preview ───
                      SliverToBoxAdapter(
                        child: FadeInUp(
                          duration: const Duration(milliseconds: 500),
                          delay: const Duration(milliseconds: 190),
                          child: const _GamificationPreview(),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: state.recentCourses.length,
                                itemBuilder: (context, index) =>
                                    _ContinueLearningCard(
                                      course: state.recentCourses[index],
                                      cardWidth: isWide ? 320 : 280,
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
                                const Icon(
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
                      else if (isWide)
                        // Tablet/Desktop: Course Grid
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridCols,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 2.5,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                delay: Duration(
                                  milliseconds: 350 + (index * 50),
                                ),
                                child: _CourseListItem(
                                  course: state.enrolledCourses[index],
                                ),
                              ),
                              childCount: state.enrolledCourses.length.clamp(
                                0,
                                8,
                              ),
                            ),
                          ),
                        )
                      else
                        // Phone: Course List
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => FadeInUp(
                                duration: const Duration(milliseconds: 400),
                                delay: Duration(
                                  milliseconds: 350 + (index * 50),
                                ),
                                child: _CourseListItem(
                                  course: state.enrolledCourses[index],
                                ),
                              ),
                              childCount: state.enrolledCourses.length.clamp(
                                0,
                                5,
                              ),
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),
            );
          }

          return const SizedBox();
        },
      ),
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
          // Back button – always show, uses GoRouter to go back to admin
          Builder(
            builder: (ctx) {
              final authState = ctx.read<AuthBloc>().state;
              final isAdmin = authState is AuthAuthenticated &&
                  authState.user.isAdmin;
              if (!isAdmin) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  tooltip: tr('common.back'),
                  onPressed: () => ctx.go('/admin'),
                ),
              );
            },
          ),
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
      _QuickItem(
        Icons.auto_awesome_rounded,
        tr('ai.smart_assistant'),
        const Color(0xFF7C3AED),
        () => context.push('/student/ai-insights'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          final crossAxisCount = isWide ? 5 : 3;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: item.color.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, color: item.color, size: 28),
                      ),
                      const Spacer(),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
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
  final double cardWidth;

  const _ContinueLearningCard({required this.course, this.cardWidth = 280});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (course.progress ?? 0) / 100;

    return Container(
      width: cardWidth,
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
                        placeholder: (_, _) => Container(
                          color: AppColors.primarySurface,
                          child: const Center(
                            child: Icon(Icons.image, color: AppColors.primary),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
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
                          placeholder: (_, _) =>
                              Container(color: AppColors.primarySurface),
                          errorWidget: (_, _, _) => Container(
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

// ─── AI Insights Preview Card ───
class _AiInsightsPreview extends StatelessWidget {
  final int userId;

  const _AiInsightsPreview({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AiInsightsBloc, AiInsightsState>(
      builder: (context, state) {
        if (state is AiInsightsLoading) {
          return _buildShimmerCard();
        }

        if (state is AiInsightsLoaded) {
          final insights = state.insights;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.push('/student/ai-insights'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7C3AED).withValues(alpha: 0.08),
                        const Color(0xFF2563EB).withValues(alpha: 0.05),
                      ],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF7C3AED,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF7C3AED),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('ai.insights'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    tr('ai.insights_desc'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.textTertiaryLight,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // Metrics row
                        Row(
                          children: [
                            _AiMetricChip(
                              icon: Icons.trending_up_rounded,
                              label: tr('ai.overall_performance'),
                              value:
                                  '${insights.overallPerformance.toStringAsFixed(0)}%',
                              color: _performanceColor(
                                insights.overallPerformance,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _AiMetricChip(
                              icon: Icons.local_fire_department_rounded,
                              label: tr('ai.study_streak'),
                              value: '${insights.studyStreak}',
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            _AiMetricChip(
                              icon: Icons.schedule_rounded,
                              label: tr('ai.weekly_hours'),
                              value:
                                  '${insights.weeklyActivityHours.toStringAsFixed(1)}h',
                              color: AppColors.info,
                            ),
                          ],
                        ),
                        // Recommendations preview
                        if (insights.recommendations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF7C3AED),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    insights.recommendations.first.reasonText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Error or initial — show a compact invite to try AI
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF7C3AED),
                  size: 22,
                ),
              ),
              title: Text(
                tr('ai.smart_assistant'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                tr('ai.insights_desc'),
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/student/ai-insights'),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Color _performanceColor(double performance) {
    if (performance >= 75) return AppColors.success;
    if (performance >= 50) return AppColors.warning;
    return AppColors.error;
  }
}

// ─── AI Metric Chip ───
class _AiMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _AiMetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Upcoming Events Preview ───
class _UpcomingEventsPreview extends StatelessWidget {
  final List<CalendarEvent> events;

  const _UpcomingEventsPreview({required this.events});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayEvents = events.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: displayEvents.map((event) {
          final dateTime = event.startDateTime;
          final timeStr = DateFormat.jm().format(dateTime);
          final dateStr = DateFormat.MMMd().format(dateTime);

          IconData icon;
          Color color;
          switch (event.eventType) {
            case 'course':
              icon = Icons.school_rounded;
              color = AppColors.primary;
              break;
            case 'user':
              icon = Icons.person_rounded;
              color = AppColors.info;
              break;
            case 'site':
              icon = Icons.public_rounded;
              color = AppColors.accent;
              break;
            default:
              icon = Icons.event_rounded;
              color = AppColors.warning;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              title: Text(
                event.name,
                style: theme.textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$dateStr • $timeStr'
                '${event.courseName != null ? ' • ${event.courseName}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textTertiaryLight,
              ),
              onTap: () => context.push('/student/calendar'),
            ),
          );
        }).toList(),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
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

// ─── Social Learning Preview Card ───
class _SocialLearningPreview extends StatelessWidget {
  const _SocialLearningPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: AppColors.secondary.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/student/study-groups'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.secondary, AppColors.secondaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_3_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('social.social_learning'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('social.social_desc'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SocialQuickAction(
                      icon: Icons.groups_outlined,
                      label: tr('social.groups_count'),
                      onTap: () => context.push('/student/study-groups'),
                    ),
                    const SizedBox(width: 8),
                    _SocialQuickAction(
                      icon: Icons.rate_review_outlined,
                      label: tr('social.reviews_pending'),
                      onTap: () => context.push('/student/peer-reviews'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.secondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gamification Preview Card ───
class _GamificationPreview extends StatelessWidget {
  const _GamificationPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: AppColors.primary.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/student/gamification'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('gamification.gamification_hub'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr('gamification.gamification_desc'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GamificationQuickAction(
                      icon: Icons.leaderboard_rounded,
                      label: tr('gamification.leaderboard'),
                      color: AppColors.primary,
                      onTap: () => context.push('/student/leaderboard'),
                    ),
                    const SizedBox(width: 8),
                    _GamificationQuickAction(
                      icon: Icons.military_tech_rounded,
                      label: tr('gamification.badges'),
                      color: AppColors.primary,
                      onTap: () => context.push('/student/badges'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GamificationQuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _GamificationQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
