import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../cohorts/presentation/bloc/cohort_bloc.dart';
import '../../../user_management/domain/entities/managed_user.dart';
import '../../../user_management/presentation/bloc/user_management_bloc.dart';
import '../../domain/entities/enrolled_user.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';

/// Comprehensive course enrollment management page with 3 tabs:
/// 1. Enrolled Students (manage, unenroll, change role)
/// 2. Enroll New Users (search, select, assign role, enroll)
/// 3. Cohort Sync (add/remove cohorts linked to this course)
class CourseEnrollmentDetailPage extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CourseEnrollmentDetailPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CourseEnrollmentDetailPage> createState() =>
      _CourseEnrollmentDetailPageState();
}

class _CourseEnrollmentDetailPageState extends State<CourseEnrollmentDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final EnrollmentBloc _enrollBloc;
  late final UserManagementBloc _userBloc;
  late final CohortBloc _cohortBloc;

  // Enroll tab state
  final _searchController = TextEditingController();
  int _selectedRoleId = MoodleRoles.student;
  final Set<int> _selectedUserIds = {};
  List<ManagedUser> _allUsers = [];
  List<ManagedUser> _filteredUsers = [];
  bool _usersLoading = true;

  // Enrolled list
  List<EnrolledUser> _enrolledUsers = [];
  String _enrolledSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _enrollBloc = EnrollmentBloc(repository: sl());
    _userBloc = UserManagementBloc(repository: sl());
    _cohortBloc = CohortBloc(apiClient: sl());

    _enrollBloc.add(LoadEnrolledUsers(courseId: widget.courseId));
    _userBloc.add(const LoadUsers());
    _cohortBloc.add(const LoadCohorts());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _enrollBloc.close();
    _userBloc.close();
    _cohortBloc.close();
    super.dispose();
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        final q = query.toLowerCase();
        _filteredUsers = _allUsers
            .where((u) =>
                u.fullName.toLowerCase().contains(q) ||
                u.username.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  void _enrollSelected() {
    if (_selectedUserIds.isEmpty) return;
    if (_selectedUserIds.length == 1) {
      _enrollBloc.add(EnrollUser(
        courseId: widget.courseId,
        userId: _selectedUserIds.first,
        roleId: _selectedRoleId,
      ));
    } else {
      _enrollBloc.add(BulkEnrollUsers(
        courseId: widget.courseId,
        userIds: _selectedUserIds.toList(),
        roleId: _selectedRoleId,
      ));
    }
  }

  void _confirmUnenroll(EnrolledUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('enrollment.unenroll'.tr()),
        content: Text('${'enrollment.confirm_unenroll'.tr()} ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _enrollBloc.add(UnenrollUser(
                courseId: widget.courseId,
                userId: user.id,
              ));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('enrollment.unenroll'.tr()),
          ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(EnrolledUser user) {
    int newRoleId = user.roles.isNotEmpty ? user.roles.first.roleId : MoodleRoles.student;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('enrollment.change_role'.tr()),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return DropdownButtonFormField<int>(
              initialValue: newRoleId,
              decoration: InputDecoration(
                labelText: 'enrollment.role'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: MoodleRoles.student, child: Text('users.role_student'.tr())),
                DropdownMenuItem(value: MoodleRoles.teacher, child: Text('users.role_teacher'.tr())),
                DropdownMenuItem(value: MoodleRoles.editingTeacher, child: Text('users.role_editingteacher'.tr())),
                DropdownMenuItem(value: MoodleRoles.manager, child: Text('users.role_manager'.tr())),
              ],
              onChanged: (v) {
                if (v != null) setDialogState(() => newRoleId = v);
              },
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
              // Unenroll then re-enroll with new role
              _enrollBloc.add(UnenrollUser(courseId: widget.courseId, userId: user.id));
              Future.delayed(const Duration(milliseconds: 800), () {
                _enrollBloc.add(EnrollUser(
                  courseId: widget.courseId,
                  userId: user.id,
                  roleId: newRoleId,
                ));
              });
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSyncCohortDialog() {
    final cohortState = _cohortBloc.state;
    if (cohortState is! CohortsLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('enrollment.loading_cohorts'.tr())),
      );
      return;
    }
    int? selectedCohortId;
    int syncRoleId = MoodleRoles.student;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('enrollment.sync_cohort'.tr()),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedCohortId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'enrollment.select_cohort'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.groups),
                  ),
                  items: cohortState.cohorts.map((c) {
                    return DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedCohortId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: syncRoleId,
                  decoration: InputDecoration(
                    labelText: 'enrollment.role'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.admin_panel_settings),
                  ),
                  items: [
                    DropdownMenuItem(value: MoodleRoles.student, child: Text('users.role_student'.tr())),
                    DropdownMenuItem(value: MoodleRoles.teacher, child: Text('users.role_teacher'.tr())),
                    DropdownMenuItem(value: MoodleRoles.editingTeacher, child: Text('users.role_editingteacher'.tr())),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => syncRoleId = v);
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
              if (selectedCohortId == null) return;
              Navigator.pop(ctx);
              _cohortBloc.add(SyncCohortToCourse(
                cohortid: selectedCohortId!,
                courseid: widget.courseId,
                roleid: syncRoleId,
              ));
              // Refresh enrolled users after a delay
              Future.delayed(const Duration(seconds: 1), () {
                _enrollBloc.add(LoadEnrolledUsers(courseId: widget.courseId));
              });
            },
            child: Text('enrollment.sync'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _enrollBloc),
        BlocProvider.value(value: _userBloc),
        BlocProvider.value(value: _cohortBloc),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<EnrollmentBloc, EnrollmentState>(
            listener: (context, state) {
              if (state is EnrolledUsersLoaded) {
                setState(() => _enrolledUsers = state.users);
              }
              if (state is UserEnrolled || state is BulkUsersEnrolled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('enrollment.user_enrolled'.tr())),
                );
                setState(() => _selectedUserIds.clear());
                _enrollBloc.add(LoadEnrolledUsers(courseId: widget.courseId));
              }
              if (state is UserUnenrolled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('enrollment.user_unenrolled'.tr())),
                );
                _enrollBloc.add(LoadEnrolledUsers(courseId: widget.courseId));
              }
              if (state is EnrollmentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
          BlocListener<UserManagementBloc, UserManagementState>(
            listener: (context, state) {
              if (state is UsersLoaded) {
                setState(() {
                  _allUsers = state.users;
                  _filteredUsers = List.from(state.users);
                  _usersLoading = false;
                });
              }
            },
          ),
          BlocListener<CohortBloc, CohortState>(
            listener: (context, state) {
              if (state is CohortActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is CohortError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.courseTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'enrollment.enrolled_users'.tr(), icon: const Icon(Icons.people)),
                Tab(text: 'enrollment.enroll_users'.tr(), icon: const Icon(Icons.person_add)),
                Tab(text: 'enrollment.cohorts_tab'.tr(), icon: const Icon(Icons.groups)),
              ],
              isScrollable: true,
              tabAlignment: TabAlignment.start,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildEnrolledTab(theme),
              _buildEnrollNewTab(theme),
              _buildCohortTab(theme),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── TAB 1: Enrolled Students ─────────
  Widget _buildEnrolledTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'common.search'.tr(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surface,
              isDense: true,
            ),
            onChanged: (q) => setState(() => _enrolledSearch = q.toLowerCase()),
          ),
        ),
        Expanded(
          child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
            builder: (context, state) {
              if (state is EnrollmentLoading && _enrolledUsers.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final filtered = _enrolledSearch.isEmpty
                  ? _enrolledUsers
                  : _enrolledUsers.where((u) =>
                      u.fullName.toLowerCase().contains(_enrolledSearch) ||
                      u.email.toLowerCase().contains(_enrolledSearch) ||
                      u.username.toLowerCase().contains(_enrolledSearch)).toList();

              if (filtered.isEmpty) {
                return Center(child: Text('enrollment.no_enrolled_users'.tr()));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  _enrollBloc.add(LoadEnrolledUsers(courseId: widget.courseId));
                },
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final user = filtered[idx];
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
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) {
                          switch (action) {
                            case 'change_role':
                              _showChangeRoleDialog(user);
                              break;
                            case 'unenroll':
                              _confirmUnenroll(user);
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'change_role',
                            child: ListTile(
                              leading: const Icon(Icons.swap_horiz),
                              title: Text('enrollment.change_role'.tr()),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'unenroll',
                            child: ListTile(
                              leading: const Icon(Icons.person_remove, color: Colors.red),
                              title: Text('enrollment.unenroll'.tr(), style: const TextStyle(color: Colors.red)),
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              const Icon(Icons.people, size: 18),
              const SizedBox(width: 8),
              Text('${_enrolledUsers.length} ${'enrollment.enrolled_users'.tr()}',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // ───────── TAB 2: Enroll New Users ─────────
  Widget _buildEnrollNewTab(ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'users.search_hint'.tr(),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surface,
              isDense: true,
            ),
            onChanged: _filterUsers,
          ),
        ),
        Expanded(
          child: _usersLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredUsers.isEmpty
                  ? Center(child: Text('users.no_users'.tr()))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 160),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, idx) {
                        final user = _filteredUsers[idx];
                        // Grey out already enrolled users
                        final isEnrolled = _enrolledUsers.any((e) => e.id == user.id);
                        final selected = _selectedUserIds.contains(user.id);
                        return ListTile(
                          enabled: !isEnrolled,
                          leading: CircleAvatar(
                            backgroundImage: user.profileImageUrl != null
                                ? CachedNetworkImageProvider(user.profileImageUrl!)
                                : null,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: user.profileImageUrl == null
                                ? Text(user.initials, style: const TextStyle(fontSize: 12))
                                : null,
                          ),
                          title: Text(
                            user.displayName,
                            style: TextStyle(
                              color: isEnrolled ? Colors.grey : null,
                              decoration: isEnrolled ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Text(
                            isEnrolled ? '${user.email} • ${'enrollment.already_enrolled'.tr()}' : user.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isEnrolled ? Colors.grey : null,
                            ),
                          ),
                          trailing: isEnrolled
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : Checkbox(value: selected, onChanged: (_) {
                                  setState(() {
                                    if (selected) {
                                      _selectedUserIds.remove(user.id);
                                    } else {
                                      _selectedUserIds.add(user.id);
                                    }
                                  });
                                }),
                          onTap: isEnrolled
                              ? null
                              : () {
                                  setState(() {
                                    if (selected) {
                                      _selectedUserIds.remove(user.id);
                                    } else {
                                      _selectedUserIds.add(user.id);
                                    }
                                  });
                                },
                        );
                      },
                    ),
        ),
        if (_selectedUserIds.isNotEmpty)
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _selectedRoleId,
                    decoration: InputDecoration(
                      labelText: 'enrollment.role'.tr(),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.admin_panel_settings),
                      isDense: true,
                    ),
                    items: [
                      DropdownMenuItem(value: MoodleRoles.student, child: Text('users.role_student'.tr())),
                      DropdownMenuItem(value: MoodleRoles.teacher, child: Text('users.role_teacher'.tr())),
                      DropdownMenuItem(value: MoodleRoles.editingTeacher, child: Text('users.role_editingteacher'.tr())),
                      DropdownMenuItem(value: MoodleRoles.manager, child: Text('users.role_manager'.tr())),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRoleId = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _enrollSelected,
                      icon: const Icon(Icons.group_add),
                      label: Text('${_selectedUserIds.length} ${'enrollment.enroll_selected'.tr()}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ───────── TAB 3: Cohort Sync ─────────
  Widget _buildCohortTab(ThemeData theme) {
    return BlocBuilder<CohortBloc, CohortState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.groups, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('enrollment.cohort_sync_title'.tr(),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('enrollment.cohort_sync_desc'.tr(),
                          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _showSyncCohortDialog,
                          icon: const Icon(Icons.link),
                          label: Text('enrollment.sync_cohort'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: state is CohortsLoaded
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.cohorts.length,
                      itemBuilder: (context, idx) {
                        final cohort = state.cohorts[idx];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.groups, color: AppColors.primary),
                            ),
                            title: Text(cohort.name),
                            subtitle: Text('${cohort.membercount} ${'enrollment.members'.tr()}'),
                            trailing: FilledButton.tonal(
                              onPressed: () {
                                _cohortBloc.add(SyncCohortToCourse(
                                  cohortid: cohort.id,
                                  courseid: widget.courseId,
                                  roleid: MoodleRoles.student,
                                ));
                                Future.delayed(const Duration(seconds: 1), () {
                                  _enrollBloc.add(LoadEnrolledUsers(courseId: widget.courseId));
                                });
                              },
                              child: Text('enrollment.sync'.tr()),
                            ),
                          ),
                        );
                      },
                    )
                  : state is CohortLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(child: Text('enrollment.no_cohorts'.tr())),
            ),
          ],
        );
      },
    );
  }
}
