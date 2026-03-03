import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/managed_user.dart';
import '../bloc/user_management_bloc.dart';

/// User detail page with view/edit mode, password reset, and suspend toggle.
class UserDetailPage extends StatefulWidget {
  final int userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late final UserManagementBloc _bloc;
  bool _isEditing = false;
  ManagedUser? _user;

  // Edit controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _institutionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = UserManagementBloc(repository: sl())
      ..add(LoadUserDetail(userId: widget.userId));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _institutionController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _populateControllers(ManagedUser user) {
    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _emailController.text = user.email;
    _departmentController.text = user.department ?? '';
    _institutionController.text = user.institution ?? '';
    _cityController.text = user.city ?? '';
    _countryController.text = user.country ?? '';
  }

  void _saveChanges() {
    _bloc.add(
      UpdateUser(
        userId: widget.userId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        department: _departmentController.text.trim().isNotEmpty
            ? _departmentController.text.trim()
            : null,
        institution: _institutionController.text.trim().isNotEmpty
            ? _institutionController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        country: _countryController.text.trim().isNotEmpty
            ? _countryController.text.trim()
            : null,
      ),
    );
  }

  void _showResetPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('users.reset_password'.tr()),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'users.new_password'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              final pwd = passwordController.text.trim();
              if (pwd.length >= 8) {
                Navigator.pop(ctx);
                _bloc.add(
                  ResetUserPassword(userId: widget.userId, newPassword: pwd),
                );
              }
            },
            child: Text('users.reset_password'.tr()),
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
          title: Text(_user?.fullName ?? 'users.user_detail'.tr()),
          actions: [
            if (_user != null && !_isEditing)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() => _isEditing = true);
                  _populateControllers(_user!);
                },
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _isEditing = false),
              ),
          ],
        ),
        body: BlocConsumer<UserManagementBloc, UserManagementState>(
          listener: (context, state) {
            if (state is UserDetailLoaded) {
              setState(() => _user = state.user);
            }
            if (state is UserUpdated) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('users.updated'.tr())));
              setState(() => _isEditing = false);
              _bloc.add(LoadUserDetail(userId: widget.userId));
            }
            if (state is PasswordReset) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('users.password_reset_success'.tr())),
              );
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
              _bloc.add(LoadUserDetail(userId: widget.userId));
            }
            if (state is UserDeleted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('users.deleted'.tr())));
              context.pop();
            }
            if (state is UserManagementError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is UserManagementLoading && _user == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_user == null) return const SizedBox.shrink();
            final user = _user!;

            if (_isEditing) {
              return _buildEditView(theme);
            }
            return _buildDetailView(theme, user);
          },
        ),
      ),
    );
  }

  Widget _buildDetailView(ThemeData theme, ManagedUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundImage: user.profileImageUrl != null
                        ? CachedNetworkImageProvider(user.profileImageUrl!)
                        : null,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: user.profileImageUrl == null
                        ? Text(
                            user.initials,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.fullName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status & role badges
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(
                          user.isActive ? Icons.check_circle : Icons.block,
                          size: 16,
                          color: user.isActive ? Colors.green : Colors.red,
                        ),
                        label: Text(
                          user.isActive
                              ? 'users.active'.tr()
                              : 'users.suspended'.tr(),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      ...user.roles.map(
                        (r) => Chip(
                          label: Text(r.name.isNotEmpty ? r.name : r.shortName),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'users.info'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  _InfoRow(
                    icon: Icons.email,
                    label: 'Email',
                    value: user.email,
                  ),
                  if (user.department?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.business,
                      label: 'users.department'.tr(),
                      value: user.department!,
                    ),
                  if (user.institution?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.account_balance,
                      label: 'users.institution'.tr(),
                      value: user.institution!,
                    ),
                  if (user.city?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.location_city,
                      label: 'users.city'.tr(),
                      value: user.city!,
                    ),
                  if (user.country?.isNotEmpty == true)
                    _InfoRow(
                      icon: Icons.flag,
                      label: 'users.country'.tr(),
                      value: user.country!,
                    ),
                  if (user.lastAccessDate != null)
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'users.last_access'.tr(),
                      value:
                          '${user.lastAccessDate!.day}/${user.lastAccessDate!.month}/${user.lastAccessDate!.year}',
                    ),
                  if (user.auth != null)
                    _InfoRow(
                      icon: Icons.vpn_key,
                      label: 'users.auth_method'.tr(),
                      value: user.auth!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin.quick_actions'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: Text('users.reset_password'.tr()),
                    onTap: _showResetPasswordDialog,
                  ),
                  ListTile(
                    leading: Icon(
                      user.suspended ? Icons.lock_open : Icons.block,
                      color: user.suspended ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      user.suspended
                          ? 'users.activate'.tr()
                          : 'users.suspend'.tr(),
                    ),
                    onTap: () {
                      _bloc.add(
                        ToggleUserSuspension(
                          userId: user.id,
                          suspend: !user.suspended,
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.group_add, color: Colors.blue),
                    title: Text('users.enroll_in_course'.tr()),
                    onTap: () =>
                        context.push('/admin/enrollment?userId=${user.id}'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: Text(
                      'users.delete_user'.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('users.delete_user'.tr()),
                          content: Text('users.confirm_delete'.tr()),
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
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text('common.delete'.tr()),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'users.edit_user'.tr(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _firstNameController,
            label: 'users.first_name'.tr(),
            icon: Icons.person,
          ),
          _buildTextField(
            controller: _lastNameController,
            label: 'users.last_name'.tr(),
            icon: Icons.person_outline,
          ),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          _buildTextField(
            controller: _departmentController,
            label: 'users.department'.tr(),
            icon: Icons.business,
          ),
          _buildTextField(
            controller: _institutionController,
            label: 'users.institution'.tr(),
            icon: Icons.account_balance,
          ),
          _buildTextField(
            controller: _cityController,
            label: 'users.city'.tr(),
            icon: Icons.location_city,
          ),
          _buildTextField(
            controller: _countryController,
            label: 'users.country'.tr(),
            icon: Icons.flag,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveChanges,
              icon: const Icon(Icons.save),
              label: Text('common.save'.tr()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryLight),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
