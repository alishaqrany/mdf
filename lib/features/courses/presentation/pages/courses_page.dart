import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/course.dart';
import '../bloc/courses_bloc.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CoursesBloc>()..add(const LoadEnrolledCourses()),
      child: const _CoursesView(),
    );
  }
}

class _CoursesView extends StatefulWidget {
  const _CoursesView();

  @override
  State<_CoursesView> createState() => _CoursesViewState();
}

class _CoursesViewState extends State<_CoursesView>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _isGridView = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('courses.my_courses')),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.list_rounded : Icons.grid_view_rounded,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: tr('courses.search_courses'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              context.read<CoursesBloc>().add(
                                const LoadEnrolledCourses(),
                              );
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      context.read<CoursesBloc>().add(
                        SearchCoursesEvent(query: query.trim()),
                      );
                    }
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Tabs
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: tr('courses.all')),
                  Tab(text: tr('courses.in_progress')),
                  Tab(text: tr('courses.completed')),
                ],
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<CoursesBloc, CoursesState>(
        builder: (context, state) {
          if (state is CoursesLoading) {
            return const _CoursesShimmer();
          }

          if (state is CoursesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<CoursesBloc>().add(
                        const LoadEnrolledCourses(),
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is CoursesLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // All Courses
                _CoursesList(courses: state.courses, isGrid: _isGridView),
                // In Progress
                _CoursesList(
                  courses: state.courses
                      .where(
                        (c) => (c.progress ?? 0) > 0 && (c.progress ?? 0) < 100,
                      )
                      .toList(),
                  isGrid: _isGridView,
                  emptyMessage: tr('courses.no_in_progress'),
                ),
                // Completed
                _CoursesList(
                  courses: state.courses
                      .where((c) => (c.progress ?? 0) >= 100)
                      .toList(),
                  isGrid: _isGridView,
                  emptyMessage: tr('courses.no_completed'),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

// ─── Courses List / Grid ───
class _CoursesList extends StatelessWidget {
  final List<Course> courses;
  final bool isGrid;
  final String? emptyMessage;

  const _CoursesList({
    required this.courses,
    required this.isGrid,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: AppColors.textTertiaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage ?? tr('courses.no_courses'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (isGrid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) => FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 50),
          child: _CourseGridCard(course: courses[index]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) => FadeInUp(
        duration: const Duration(milliseconds: 400),
        delay: Duration(milliseconds: index * 50),
        child: _CourseListCard(course: courses[index]),
      ),
    );
  }
}

// ─── Grid Card ───
class _CourseGridCard extends StatelessWidget {
  final Course course;

  const _CourseGridCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (course.progress ?? 0) / 100;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Navigate to course detail
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: SizedBox(
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
                            size: 40,
                          ),
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (course.categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.categoryName!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      course.fullName,
                      style: theme.textTheme.titleSmall?.copyWith(height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    LinearPercentIndicator(
                      lineHeight: 5,
                      percent: progress.clamp(0.0, 1.0),
                      backgroundColor: AppColors.primarySurface,
                      progressColor: progress >= 1.0
                          ? AppColors.success
                          : AppColors.primary,
                      barRadius: const Radius.circular(3),
                      padding: EdgeInsets.zero,
                      trailing: Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List Card ───
class _CourseListCard extends StatelessWidget {
  final Course course;

  const _CourseListCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (course.progress ?? 0) / 100;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to course detail
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
                  width: 80,
                  height: 80,
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
                    if (course.categoryName != null)
                      Text(
                        course.categoryName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      course.fullName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearPercentIndicator(
                            lineHeight: 5,
                            percent: progress.clamp(0.0, 1.0),
                            backgroundColor: AppColors.primarySurface,
                            progressColor: progress >= 1.0
                                ? AppColors.success
                                : AppColors.primary,
                            barRadius: const Radius.circular(3),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: progress >= 1.0
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.textTertiaryLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer ───
class _CoursesShimmer extends StatelessWidget {
  const _CoursesShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.72,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
