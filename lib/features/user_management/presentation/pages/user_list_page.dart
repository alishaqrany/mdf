import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/managed_user.dart';
import '../bloc/user_management_bloc.dart';

/// Lists users with search, role filter, and quick actions.
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late final UserManagementBloc _bloc;
  final _searchController = TextEditingController();
  String? _selectedRole;

  static const _roles = [
    null, // All
    'manager',
    'editingteacher',
    'teacher',
    'student',
  ];

  @override
  void initState() {
    super.initState();
    _bloc = UserManagementBloc(repository: sl())..add(const LoadUsers());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _bloc.add(SearchUsers(query: query));
    } else {
      _bloc.add(LoadUsers(roleFilter: _selectedRole));
    }
  }

  void _onRoleFilter(String? role) {
    setState(() => _selectedRole = role);
    _searchController.clear();
    _bloc.add(LoadUsers(roleFilter: role));
  }

  String _roleLabel(String? role) {
    if (role == null) return 'users.all_roles'.tr();
    return 'users.role_$role'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('users.title'.tr()),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _onSearch(),
                decoration: InputDecoration(
                  hintText: 'users.search_hint'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _bloc.add(LoadUsers(roleFilter: _selectedRole));
                    },
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Role filter chips
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _roles.map((role) {
                  final selected = _selectedRole == role;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(_roleLabel(role)),
                      selected: selected,
                      onSelected: (_) => _onRoleFilter(role),
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // User list
            Expanded(
              child: BlocConsumer<UserManagementBloc, UserManagementState>(
                listener: (context, state) {
                  if (state is UserDeleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('users.deleted'.tr())),
                    );
                    _bloc.add(LoadUsers(roleFilter: _selectedRole));
                  }
                  if (state is UserSuspensionToggled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.suspended
                              ? 'users.suspended'.tr()
                              : 'users.activated'.tr(),
                        ),
                      ),
                    );
                    _bloc.add(LoadUsers(roleFilter: _selectedRole));
                  }
                  if (state is UserManagementError) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                buildWhen: (prev, curr) =>
                    curr is UsersLoaded ||
                    curr is UserManagementLoading ||
                    curr is UserManagementError,
                builder: (context, state) {
                  if (state is UserManagementLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text('users.no_users'.tr()),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        _bloc.add(LoadUsers(roleFilter: _selectedRole));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.users.length,
                        itemBuilder: (context, index) {
                          return _UserCard(
                            user: state.users[index],
                            onTap: () => context.push(
                              '/admin/users/${state.users[index].id}',
                            ),
                            onSuspendToggle: () {
                              final u = state.users[index];
                              _bloc.add(
                                ToggleUserSuspension(
                                  userId: u.id,
                                  suspend: !u.suspended,
                                ),
                              );
                            },
                            onDelete: () =>
                                _confirmDelete(context, state.users[index]),
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final created = await context.push<bool>('/admin/users/create');
            if (created == true) {
              _bloc.add(LoadUsers(roleFilter: _selectedRole));
            }
          },
          icon: const Icon(Icons.person_add),
          label: Text('users.add_user'.tr()),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ManagedUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('users.delete_user'.tr()),
        content: Text(
          '${'users.confirm_delete'.tr()}\n\n${user.fullName} (${user.username})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(DeleteUser(userId: user.id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('common.delete'.tr()),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final ManagedUser user;
  final VoidCallback onTap;
  final VoidCallback onSuspendToggle;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onTap,
    required this.onSuspendToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundImage: user.profileImageUrl != null
                    ? CachedNetworkImageProvider(user.profileImageUrl!)
                    : null,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: user.profileImageUrl == null
                    ? Text(
                        user.initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.fullName,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.suspended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'users.suspended'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RoleChip(role: user.primaryRole),
                        if (user.lastAccessDate != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDate(user.lastAccessDate!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.visibility, size: 20),
                      title: Text('users.view'.tr()),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'suspend',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        user.suspended ? Icons.lock_open : Icons.block,
                        size: 20,
                      ),
                      title: Text(
                        user.suspended
                            ? 'users.activate'.tr()
                            : 'users.suspend'.tr(),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      title: Text(
                        'common.delete'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      onTap();
                    case 'suspend':
                      onSuspendToggle();
                    case 'delete':
                      onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _roleStyle(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            'users.role_$role'.tr(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _roleStyle(String role) {
    return switch (role) {
      'manager' => (Colors.purple, Icons.admin_panel_settings),
      'editingteacher' => (Colors.blue, Icons.school),
      'teacher' => (Colors.teal, Icons.person),
      'student' => (Colors.green, Icons.person_outline),
      _ => (Colors.grey, Icons.person),
    };
  }
}
