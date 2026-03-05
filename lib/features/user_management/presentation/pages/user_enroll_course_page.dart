import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/repositories/courses_repository.dart';
import '../../../enrollment/domain/entities/enrolled_user.dart';
import '../../../enrollment/presentation/bloc/enrollment_bloc.dart';
import '../../../enrollment/presentation/bloc/enrollment_event.dart';
import '../../../enrollment/presentation/bloc/enrollment_state.dart';

/// Page that shows courses a specific user is NOT enrolled in,
/// allowing the admin to enroll them with role selection.
class UserEnrollCoursePage extends StatefulWidget {
  final int userId;
  final String userName;

  const UserEnrollCoursePage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserEnrollCoursePage> createState() => _UserEnrollCoursePageState();
}

class _UserEnrollCoursePageState extends State<UserEnrollCoursePage> {
  late final EnrollmentBloc _enrollBloc;
  List<Course> _unenrolledCourses = [];
  List<Course> _filteredCourses = [];
  Set<int> _enrolledCourseIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _enrollBloc = EnrollmentBloc(repository: sl());
    _loadData();
  }

  @override
  void dispose() {
    _enrollBloc.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Load all courses
    final coursesRepo = sl<CoursesRepository>();

    final coursesResult = await coursesRepo.getAllCourses();
    List<Course> allCourses = [];
    coursesResult.fold(
      (f) => {},
      (courses) {
        courses.removeWhere((c) => c.fullName.trim().isEmpty);
        allCourses = courses;
      },
    );

    // For each course, check if user is enrolled
    // This is done by fetching enrolled users for each course and checking
    // A more efficient approach: use core_enrol_get_users_courses for the user
    Set<int> enrolledIds = {};

    // Get user's enrolled courses
    try {
      final userCoursesResult = await coursesRepo.getEnrolledCourses(widget.userId);
      userCoursesResult.fold(
        (f) => {},
        (courses) {
          enrolledIds = courses.map((c) => c.id).toSet();
        },
      );
    } catch (_) {
      // Fallback: leave empty, show all courses
    }

    if (!mounted) return;

    setState(() {
      _enrolledCourseIds = enrolledIds;
      _unenrolledCourses = allCourses.where((c) => !enrolledIds.contains(c.id)).toList();
      _filteredCourses = List.from(_unenrolledCourses);
      _loading = false;
    });
  }

  void _filterCourses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCourses = List.from(_unenrolledCourses);
      } else {
        final q = query.toLowerCase();
        _filteredCourses = _unenrolledCourses
            .where((c) =>
                c.fullName.toLowerCase().contains(q) ||
                c.shortName.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  void _showEnrollDialog(Course course) {
    int roleId = MoodleRoles.student;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('enrollment.enroll_user'.tr()),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${'enrollment.enroll_in'.tr()} ${course.fullName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: roleId,
                  decoration: InputDecoration(
                    labelText: 'enrollment.role'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                  ),
                  items: [
                    DropdownMenuItem(value: MoodleRoles.student, child: Text('users.role_student'.tr())),
                    DropdownMenuItem(value: MoodleRoles.teacher, child: Text('users.role_teacher'.tr())),
                    DropdownMenuItem(value: MoodleRoles.editingTeacher, child: Text('users.role_editingteacher'.tr())),
                    DropdownMenuItem(value: MoodleRoles.manager, child: Text('users.role_manager'.tr())),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => roleId = v);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _enrollBloc.add(EnrollUser(
                courseId: course.id,
                userId: widget.userId,
                roleId: roleId,
              ));
            },
            child: Text('enrollment.enroll'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _enrollBloc,
      child: BlocListener<EnrollmentBloc, EnrollmentState>(
        listener: (context, state) {
          if (state is UserEnrolled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('enrollment.user_enrolled'.tr())),
            );
            _loadData(); // Refresh to remove enrolled course
          }
          if (state is EnrollmentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('${'enrollment.enroll_user'.tr()} - ${widget.userName}'),
          ),
          body: Column(
            children: [
              // Info banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'enrollment.select_course_for_user'.tr(),
                        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
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
              // Count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${_filteredCourses.length} ${'enrollment.unenrolled_courses'.tr()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
                    ),
                    const Spacer(),
                    Text(
                      '${_enrolledCourseIds.length} ${'enrollment.enrolled_courses'.tr()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Course list
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredCourses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                                const SizedBox(height: 12),
                                Text('enrollment.enrolled_in_all'.tr(),
                                    style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _filteredCourses.length,
                            itemBuilder: (context, idx) {
                              final course = _filteredCourses[idx];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: ListTile(
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
                                  title: Text(course.fullName, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text('${course.shortName} • ID: ${course.id}',
                                      style: theme.textTheme.bodySmall),
                                  trailing: FilledButton.tonal(
                                    onPressed: () => _showEnrollDialog(course),
                                    child: Text('enrollment.enroll'.tr()),
                                  ),
                                  onTap: () => _showEnrollDialog(course),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
