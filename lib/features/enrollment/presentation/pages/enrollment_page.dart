import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/enrolled_user.dart';
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
  final _courseIdController = TextEditingController();
  int? _currentCourseId;

  @override
  void initState() {
    super.initState();
    _bloc = EnrollmentBloc(repository: sl());
    if (widget.preselectedCourseId != null) {
      _currentCourseId = widget.preselectedCourseId;
      _courseIdController.text = widget.preselectedCourseId.toString();
      _bloc.add(LoadEnrolledUsers(courseId: widget.preselectedCourseId!));
    }
  }

  @override
  void dispose() {
    _courseIdController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadCourse() {
    final id = int.tryParse(_courseIdController.text.trim());
    if (id != null && id > 0) {
      setState(() => _currentCourseId = id);
      _bloc.add(LoadEnrolledUsers(courseId: id));
    }
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
            // Course ID input
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _courseIdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'enrollment.course_id'.tr(),
                        hintText: 'enrollment.enter_course_id'.tr(),
                        prefixIcon: const Icon(Icons.school),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _loadCourse(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _loadCourse,
                    child: Text('enrollment.load'.tr()),
                  ),
                ],
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
