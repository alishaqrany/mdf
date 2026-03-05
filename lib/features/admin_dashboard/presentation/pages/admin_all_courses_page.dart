import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/repositories/courses_repository.dart';

/// Admin-only page showing ALL platform courses (not just enrolled).
/// Allows preview and management of any course.
class AdminAllCoursesPage extends StatefulWidget {
  const AdminAllCoursesPage({super.key});

  @override
  State<AdminAllCoursesPage> createState() => _AdminAllCoursesPageState();
}

class _AdminAllCoursesPageState extends State<AdminAllCoursesPage> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _loading = true;
  String _error = '';
  bool _gridView = true;

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  Future<void> _loadAllCourses() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    final coursesRepo = sl<CoursesRepository>();
    final result = await coursesRepo.getAllCourses();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.toString();
      }),
      (courses) {
        courses.removeWhere((c) => c.fullName.trim().isEmpty);
        setState(() {
          _allCourses = courses;
          _filteredCourses = List.from(courses);
          _loading = false;
        });
      },
    );
  }

  void _filterCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = List.from(_allCourses);
      } else {
        final q = query.toLowerCase();
        _filteredCourses = _allCourses
            .where((c) =>
                c.fullName.toLowerCase().contains(q) ||
                c.shortName.toLowerCase().contains(q) ||
                (c.categoryName ?? '').toLowerCase().contains(q) ||
                c.id.toString().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.all_courses'.tr()),
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
            tooltip: _gridView ? 'List view' : 'Grid view',
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllCourses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'enrollment.search_courses'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surface,
                isDense: true,
              ),
              onChanged: _filterCourses,
            ),
          ),
          // Stats bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.school, size: 18, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(
                  '${_filteredCourses.length} / ${_allCourses.length} ${'admin.all_courses'.tr()}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error),
                            const SizedBox(height: 12),
                            FilledButton(onPressed: _loadAllCourses, child: Text('common.retry'.tr())),
                          ],
                        ),
                      )
                    : _filteredCourses.isEmpty
                        ? Center(child: Text('common.no_results'.tr()))
                        : RefreshIndicator(
                            onRefresh: _loadAllCourses,
                            child: _gridView ? _buildGrid(theme) : _buildList(theme),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 900
            ? 4
            : MediaQuery.of(context).size.width > 600
                ? 3
                : 2,
        childAspectRatio: 0.78,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredCourses.length,
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return _AdminCourseCard(
          course: course,
          onTap: () => _openCourse(course),
          onManage: () => _manageCourse(course),
        );
      },
    );
  }

  Widget _buildList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _filteredCourses.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final course = _filteredCourses[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: course.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.school, color: AppColors.primary),
                      ),
                    )
                  : Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.school, color: AppColors.primary),
                    ),
            ),
          ),
          title: Text(course.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${course.shortName} • ID: ${course.id}${course.categoryName != null ? ' • ${course.categoryName}' : ''}',
            style: theme.textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'view':
                  _openCourse(course);
                  break;
                case 'enrollment':
                  _manageCourse(course);
                  break;
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'view',
                child: ListTile(
                  leading: const Icon(Icons.visibility),
                  title: Text('admin.preview_course'.tr()),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'enrollment',
                child: ListTile(
                  leading: const Icon(Icons.people),
                  title: Text('enrollment.title'.tr()),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          onTap: () => _openCourse(course),
        );
      },
    );
  }

  void _openCourse(Course course) {
    context.push(
      '/admin/course/${course.id}?title=${Uri.encodeComponent(course.fullName)}${course.imageUrl != null ? '&image=${Uri.encodeComponent(course.imageUrl!)}' : ''}',
    );
  }

  void _manageCourse(Course course) {
    context.push(
      '/admin/enrollment/${course.id}?title=${Uri.encodeComponent(course.fullName)}',
    );
  }
}

class _AdminCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;
  final VoidCallback onManage;

  const _AdminCourseCard({
    required this.course,
    required this.onTap,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course image
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: course.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: Icon(Icons.school, size: 36, color: AppColors.primary),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.school, size: 36, color: AppColors.primary),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.school, size: 36, color: AppColors.primary),
                          ),
                  ),
                  // Visibility badge
                  if (course.visible == false)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Hidden', style: TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  // ID badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('#${course.id}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        if (course.categoryName != null)
                          Expanded(
                            child: Text(
                              course.categoryName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight),
                            ),
                          ),
                        InkWell(
                          onTap: onManage,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.people, size: 16, color: AppColors.primary),
                          ),
                        ),
                      ],
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
