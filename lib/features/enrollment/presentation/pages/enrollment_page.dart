import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/enrolled_user.dart';
import '../../../../features/courses/domain/entities/course.dart';
import '../../../../features/courses/domain/repositories/courses_repository.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';
import 'enroll_user_page.dart';

/// Page to manage enrollment for a specific course.
/// Shows enrolled users with ability to enroll/unenroll.
class EnrollmentPage extends StatefulWidget {
  final int? preselectedCourseId;

  const EnrollmentPage({super.key, this.preselectedCourseId});

  @override
  State<EnrollmentPage> createState() => _EnrollmentPageState();
}

class _EnrollmentPageState extends State<EnrollmentPage> {
  late final EnrollmentBloc _bloc;
  int? _currentCourseId;
  List<Course>? _allCourses;
  bool _loadingCourses = true;

  @override
  void initState() {
    super.initState();
    _bloc = EnrollmentBloc(repository: sl());
    if (widget.preselectedCourseId != null) {
      _currentCourseId = widget.preselectedCourseId;
      _bloc.add(LoadEnrolledUsers(courseId: widget.preselectedCourseId!));
    }
    _loadAllCourses();
  }

  Future<void> _loadAllCourses() async {
    final coursesRepo = sl<CoursesRepository>();
    final result = await coursesRepo.getAllCourses();
    if (mounted) {
      setState(() {
        _loadingCourses = false;
        result.fold(
          (failure) => _allCourses = [],
          (courses) => _allCourses = courses,
        );
        // Clean up course list
        _allCourses?.removeWhere((c) => c.fullName.trim().isEmpty);

        // Ensure current course ID is valid if set
        if (_currentCourseId != null && _allCourses != null) {
          final exists = _allCourses!.any((c) => c.id == _currentCourseId);
          if (!exists) {
            _currentCourseId = null;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _loadCourse(int id) {
    setState(() => _currentCourseId = id);
    _bloc.add(LoadEnrolledUsers(courseId: id));
  }

  void _confirmUnenroll(EnrolledUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('enrollment.unenroll'.tr()),
        content: Text(
          '${'enrollment.confirm_unenroll'.tr()} ${user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(
                UnenrollUser(courseId: _currentCourseId!, userId: user.id),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('enrollment.unenroll'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('enrollment.title'.tr()),
          actions: [
            if (_currentCourseId != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () =>
                    _bloc.add(LoadEnrolledUsers(courseId: _currentCourseId!)),
              ),
          ],
        ),
        floatingActionButton: _currentCourseId != null
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          EnrollUserPage(courseId: _currentCourseId!),
                    ),
                  );
                  if (result == true && _currentCourseId != null) {
                    _bloc.add(LoadEnrolledUsers(courseId: _currentCourseId!));
                  }
                },
                icon: const Icon(Icons.person_add),
                label: Text('enrollment.enroll_user'.tr()),
              )
            : null,
        body: Column(
          children: [
            // Course selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: _loadingCourses
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      value: _currentCourseId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'courses.my_courses'.tr(), // Or 'enrollment.select_course'.tr() if available
                        hintText: 'enrollment.enter_course_id'.tr(),
                        prefixIcon: const Icon(Icons.school),
                        border: const OutlineInputBorder(),
                      ),
                      items: _allCourses?.map((course) {
                        return DropdownMenuItem<int>(
                          value: course.id,
                          child: Text(course.fullName),
                        );
                      }).toList() ?? [],
                      onChanged: (id) {
                        if (id != null) _loadCourse(id);
                      },
                    ),
            ),
            const Divider(height: 1),

            // Enrolled users list
            Expanded(
              child: BlocConsumer<EnrollmentBloc, EnrollmentState>(
                listener: (context, state) {
                  if (state is UserEnrolled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('enrollment.user_enrolled'.tr())),
                    );
                    _bloc.add(LoadEnrolledUsers(courseId: _currentCourseId!));
                  }
                  if (state is BulkUsersEnrolled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${'enrollment.bulk_enrolled'.tr()} (${state.count})',
                        ),
                      ),
                    );
                    _bloc.add(LoadEnrolledUsers(courseId: _currentCourseId!));
                  }
                  if (state is UserUnenrolled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('enrollment.user_unenrolled'.tr()),
                      ),
                    );
                    _bloc.add(LoadEnrolledUsers(courseId: _currentCourseId!));
                  }
                  if (state is EnrollmentError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  if (_currentCourseId == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'enrollment.select_course'.tr(),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is EnrollmentLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is EnrolledUsersLoaded) {
                    if (state.users.isEmpty) {
                      return Center(
                        child: Text('enrollment.no_enrolled_users'.tr()),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        _bloc.add(
                          LoadEnrolledUsers(courseId: _currentCourseId!),
                        );
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: state.users.length,
                        itemBuilder: (context, idx) {
                          final user = state.users[idx];
                          return _EnrolledUserTile(
                            user: user,
                            onUnenroll: () => _confirmUnenroll(user),
                          );
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnrolledUserTile extends StatelessWidget {
  final EnrolledUser user;
  final VoidCallback onUnenroll;

  const _EnrolledUserTile({required this.user, required this.onUnenroll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profileImageUrl != null
            ? CachedNetworkImageProvider(user.profileImageUrl!)
            : null,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: user.profileImageUrl == null
            ? Text(user.initials, style: const TextStyle(fontSize: 12))
            : null,
      ),
      title: Text(user.fullName),
      subtitle: Text(
        '${user.email} • ${user.primaryRoleName}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.person_remove, color: Colors.red),
        tooltip: 'enrollment.unenroll'.tr(),
        onPressed: onUnenroll,
      ),
    );
  }
}
