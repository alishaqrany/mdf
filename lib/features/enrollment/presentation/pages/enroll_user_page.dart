import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../../user_management/domain/entities/managed_user.dart';
import '../../../user_management/presentation/bloc/user_management_bloc.dart';
import '../../domain/entities/enrolled_user.dart';
import '../bloc/enrollment_bloc.dart';
import '../bloc/enrollment_event.dart';
import '../bloc/enrollment_state.dart';

/// Page to search and enrol users in a course.
/// Supports single and bulk enrollment.
class EnrollUserPage extends StatefulWidget {
  final int courseId;

  const EnrollUserPage({super.key, required this.courseId});

  @override
  State<EnrollUserPage> createState() => _EnrollUserPageState();
}

class _EnrollUserPageState extends State<EnrollUserPage> {
  late final UserManagementBloc _userBloc;
  late final EnrollmentBloc _enrollBloc;
  final _searchController = TextEditingController();

  int _selectedRoleId = MoodleRoles.student;
  final Set<int> _selectedUserIds = {};
  bool _enrolled = false;

  @override
  void initState() {
    super.initState();
    _userBloc = UserManagementBloc(repository: sl());
    _enrollBloc = EnrollmentBloc(repository: sl());
    // Load all users initially
    _userBloc.add(const LoadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _userBloc.close();
    _enrollBloc.close();
    super.dispose();
  }

  void _enrollSelected() {
    if (_selectedUserIds.isEmpty) return;

    if (_selectedUserIds.length == 1) {
      _enrollBloc.add(
        EnrollUser(
          courseId: widget.courseId,
          userId: _selectedUserIds.first,
          roleId: _selectedRoleId,
        ),
      );
    } else {
      _enrollBloc.add(
        BulkEnrollUsers(
          courseId: widget.courseId,
          userIds: _selectedUserIds.toList(),
          roleId: _selectedRoleId,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _userBloc),
        BlocProvider.value(value: _enrollBloc),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text('enrollment.enroll_user'.tr()),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'users.search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  isDense: true,
                ),
                onChanged: (query) {
                  _userBloc.add(SearchUsers(query: query));
                },
              ),
            ),
          ),
        ),
        bottomNavigationBar: _selectedUserIds.isNotEmpty
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Role selector
                      DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: InputDecoration(
                          labelText: 'enrollment.role'.tr(),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.admin_panel_settings),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: MoodleRoles.student,
                            child: Text('users.role_student'.tr()),
                          ),
                          DropdownMenuItem(
                            value: MoodleRoles.teacher,
                            child: Text('users.role_teacher'.tr()),
                          ),
                          DropdownMenuItem(
                            value: MoodleRoles.editingTeacher,
                            child: Text('users.role_editingteacher'.tr()),
                          ),
                          DropdownMenuItem(
                            value: MoodleRoles.manager,
                            child: Text('users.role_manager'.tr()),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null)
                            setState(() => _selectedRoleId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: BlocConsumer<EnrollmentBloc, EnrollmentState>(
                          listener: (context, state) {
                            if (state is UserEnrolled ||
                                state is BulkUsersEnrolled) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'enrollment.user_enrolled'.tr(),
                                  ),
                                ),
                              );
                              setState(() {
                                _enrolled = true;
                                _selectedUserIds.clear();
                              });
                            }
                            if (state is EnrollmentError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(state.message)),
                              );
                            }
                          },
                          builder: (context, state) {
                            final loading = state is EnrollmentLoading;
                            return FilledButton.icon(
                              onPressed: loading ? null : _enrollSelected,
                              icon: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.group_add),
                              label: Text(
                                '${_selectedUserIds.length} ${'enrollment.enroll_selected'.tr()}',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
        body: WillPopScope(
          onWillPop: () async {
            Navigator.pop(context, _enrolled);
            return false;
          },
          child: BlocBuilder<UserManagementBloc, UserManagementState>(
            builder: (context, state) {
              if (state is UserManagementLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is UsersLoaded) {
                if (state.users.isEmpty) {
                  return Center(child: Text('users.no_users'.tr()));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 160),
                  itemCount: state.users.length,
                  itemBuilder: (context, idx) {
                    final user = state.users[idx];
                    final selected = _selectedUserIds.contains(user.id);
                    return _UserSelectTile(
                      user: user,
                      selected: selected,
                      onToggle: () {
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
                );
              }
              if (state is UserManagementError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _UserSelectTile extends StatelessWidget {
  final ManagedUser user;
  final bool selected;
  final VoidCallback onToggle;

  const _UserSelectTile({
    required this.user,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: user.profileImageUrl != null
            ? NetworkImage(user.profileImageUrl!)
            : null,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: user.profileImageUrl == null
            ? Text(user.initials, style: const TextStyle(fontSize: 12))
            : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(user.email),
      trailing: Checkbox(value: selected, onChanged: (_) => onToggle()),
      onTap: onToggle,
    );
  }
}
