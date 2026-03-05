import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../../features/courses/domain/entities/course.dart';
import '../../../../features/courses/domain/repositories/courses_repository.dart';

/// Redesigned Enrollment page — shows ALL courses as a searchable grid.
/// Tapping a course opens the detailed enrollment management page.
class EnrollmentPage extends StatefulWidget {
  final int? preselectedCourseId;

  const EnrollmentPage({super.key, this.preselectedCourseId});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  Future<void> _loadAllCourses() async {
    setState(() { _loading = true; _error = ''; });
    final coursesRepo = sl<CoursesRepository>();
    final result = await coursesRepo.getAllCourses();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() { _loading = false; _error = failure.toString(); }),
      (courses) {
        courses.removeWhere((c) => c.fullName.trim().isEmpty);
        setState(() {
          _allCourses = courses;
          _filteredCourses = List.from(courses);
          _loading = false;
        });
        // If a preselected courseId was passed, navigate directly
        if (widget.preselectedCourseId != null) {
          final course = courses.firstWhere(
            (c) => c.id == widget.preselectedCourseId,
            orElse: () => courses.first,
          );
          _openCourseEnrollment(course);
        }
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
                (c.categoryName ?? '').toLowerCase().contains(q))
            .toList();
      }
    });
  }

  void _openCourseEnrollment(Course course) {
    context.push(
      '/admin/enrollment/${course.id}?title=${Uri.encodeComponent(course.fullName)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('enrollment.title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllCourses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
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
          // Courses count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.school, size: 18, color: AppColors.textSecondaryLight),
                const SizedBox(width: 6),
                Text(
                  '${_filteredCourses.length} ${'enrollment.courses_available'.tr()}',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Course grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _filteredCourses.isEmpty
                        ? Center(child: Text('common.no_results'.tr()))
                        : RefreshIndicator(
                            onRefresh: _loadAllCourses,
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _filteredCourses.length,
                              itemBuilder: (context, index) {
                                final course = _filteredCourses[index];
                                return _CourseCard(
                                  course: course,
                                  onTap: () => _openCourseEnrollment(course),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _CourseCard({required this.course, required this.onTap});

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
              child: Container(
                width: double.infinity,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: course.imageUrl != null && course.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: course.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
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
            ),
            // Course info
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
                        const Icon(Icons.people, size: 14, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text(
                          'ID: ${course.id}',
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
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
