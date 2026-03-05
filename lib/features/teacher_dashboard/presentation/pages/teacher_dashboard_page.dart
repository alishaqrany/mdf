import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../courses/presentation/bloc/courses_bloc.dart';

/// Teacher Dashboard page — shows teacher's courses with quick-action links
/// for course content management, grading, etc.
class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;
    return BlocProvider(
      create: (_) =>
          sl<CoursesBloc>()..add(LoadEnrolledCourses(userId: userId)),
      child: const _TeacherDashboardView(),
    );
  }
}

class _TeacherDashboardView extends StatelessWidget {
  const _TeacherDashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = context.read<AuthBloc>().state;
    final userName = authState is AuthAuthenticated
        ? authState.user.fullName
        : '';
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;
    final teacherCourseIds = authState is AuthAuthenticated
        ? authState.user.teacherCourseIds
        : <int>[];

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context
              .read<CoursesBloc>()
              .add(LoadEnrolledCourses(userId: userId));
        },
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ───
            SliverAppBar.large(
              title: Text(
                tr('teacher.dashboard_title'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // ─── Greeting Card ───
            SliverToBoxAdapter(
              child: FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tr('teacher.welcome')}, $userName 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr('teacher.dashboard_subtitle'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Quick Actions ───
            SliverToBoxAdapter(
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    tr('teacher.quick_actions'),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeInUp(
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickActionChip(
                        icon: Icons.library_books,
                        label: tr('teacher.my_courses'),
                        onTap: () => context.go('/teacher/courses'),
                      ),
                      _QuickActionChip(
                        icon: Icons.calendar_today,
                        label: tr('nav.calendar'),
                        onTap: () => context.go('/teacher/calendar'),
                      ),
                      _QuickActionChip(
                        icon: Icons.message,
                        label: tr('nav.messages'),
                        onTap: () => context.go('/teacher/messages'),
                      ),
                      _QuickActionChip(
                        icon: Icons.notifications,
                        label: tr('nav.notifications'),
                        onTap: () => context.go('/teacher/notifications'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Courses Header ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  tr('teacher.my_courses'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ─── Courses Grid ───
            BlocBuilder<CoursesBloc, CoursesState>(
              builder: (context, state) {
                if (state is CoursesLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is CoursesError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 48),
                          const SizedBox(height: 8),
                          Text(state.message),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context
                                .read<CoursesBloc>()
                                .add(LoadEnrolledCourses(userId: userId)),
                            child: Text(tr('common.retry')),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state is CoursesLoaded) {
                  // Filter to only teacher courses
                  final courses = teacherCourseIds.isEmpty
                      ? state.courses
                      : state.courses
                          .where((c) => teacherCourseIds.contains(c.id))
                          .toList();

                  if (courses.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 64,
                              color: theme.disabledColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('teacher.no_courses'),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          return FadeInUp(
                            duration: Duration(
                                milliseconds: 400 + (index * 100)),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => context.go(
                                  '/teacher/course/${course.id}?title=${Uri.encodeComponent(course.fullName)}',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      // Course icon
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: theme.primaryColor
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: course.imageUrl != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Image.network(
                                                  course.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, e, s) => Icon(
                                                    Icons.school,
                                                    color:
                                                        theme.primaryColor,
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.school,
                                                color: theme.primaryColor,
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Course info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              course.fullName,
                                              style: theme
                                                  .textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (course.shortName.isNotEmpty)
                                              Text(
                                                course.shortName,
                                                style: theme
                                                    .textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: theme.hintColor,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Actions
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          switch (action) {
                                            case 'content':
                                              context.go(
                                                '/teacher/course/${course.id}?title=${Uri.encodeComponent(course.fullName)}',
                                              );
                                              break;
                                            case 'grades':
                                              context.go(
                                                '/grades/${course.id}',
                                              );
                                              break;
                                            case 'forums':
                                              context.go(
                                                '/forum/list/${course.id}',
                                              );
                                              break;
                                            case 'assignments':
                                              context.go(
                                                '/assignment/list/${course.id}',
                                              );
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: 'content',
                                            child: ListTile(
                                              leading: const Icon(
                                                  Icons.edit_note),
                                              title: Text(tr(
                                                  'teacher.manage_content')),
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'grades',
                                            child: ListTile(
                                              leading:
                                                  const Icon(Icons.grade),
                                              title: Text(
                                                  tr('nav.grades')),
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'assignments',
                                            child: ListTile(
                                              leading: const Icon(
                                                  Icons.assignment),
                                              title: Text(tr(
                                                  'nav.assignments')),
                                              dense: true,
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'forums',
                                            child: ListTile(
                                              leading:
                                                  const Icon(Icons.forum),
                                              title: Text(
                                                  tr('nav.forums')),
                                              dense: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: courses.length,
                      ),
                    ),
                  );
                }

                return const SliverToBoxAdapter(child: SizedBox.shrink());
              },
            ),
          ],
        ),
      ),
    );
  }
}

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
    );
  }
}
