import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../bloc/user_management_bloc.dart';

/// Create new user form page.
class UserCreatePage extends StatefulWidget {
  const UserCreatePage({super.key});

  @override
  State<UserCreatePage> createState() => _UserCreatePageState();
}

class _UserCreatePageState extends State<UserCreatePage> {
  late final UserManagementBloc _bloc;
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _departmentController = TextEditingController();
  final _institutionController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();

  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _bloc = UserManagementBloc(repository: sl());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _bloc.add(
      CreateUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: Text('users.add_user'.tr())),
        body: BlocConsumer<UserManagementBloc, UserManagementState>(
          listener: (context, state) {
            if (state is UserCreated) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('users.user_created'.tr())),
              );
              context.pop(true); // Return true to refresh list
            }
            if (state is UserManagementError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Required fields section
                        Text(
                          'users.required_info'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RequiredField(
                          controller: _usernameController,
                          label: 'users.username'.tr(),
                          icon: Icons.person,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'users.username_required'.tr();
                            }
                            if (val.trim().length < 3) {
                              return 'users.username_min_length'.tr();
                            }
                            return null;
                          },
                        ),
                        _RequiredField(
                          controller: _passwordController,
                          label: 'users.password'.tr(),
                          icon: Icons.lock,
                          obscureText: !_showPassword,
                          suffix: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'users.password_required'.tr();
                            }
                            if (val.trim().length < 8) {
                              return 'users.password_min_length'.tr();
                            }
                            return null;
                          },
                        ),
                        _RequiredField(
                          controller: _firstNameController,
                          label: 'users.first_name'.tr(),
                          icon: Icons.badge,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'users.first_name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        _RequiredField(
                          controller: _lastNameController,
                          label: 'users.last_name'.tr(),
                          icon: Icons.badge_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'users.last_name_required'.tr();
                            }
                            return null;
                          },
                        ),
                        _RequiredField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'users.email_required'.tr();
                            }
                            if (!val.contains('@') || !val.contains('.')) {
                              return 'users.email_invalid'.tr();
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Optional fields section
                        Text(
                          'users.optional_info'.tr(),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _OptionalField(
                          controller: _departmentController,
                          label: 'users.department'.tr(),
                          icon: Icons.business,
                        ),
                        _OptionalField(
                          controller: _institutionController,
                          label: 'users.institution'.tr(),
                          icon: Icons.account_balance,
                        ),
                        _OptionalField(
                          controller: _cityController,
                          label: 'users.city'.tr(),
                          icon: Icons.location_city,
                        ),
                        _OptionalField(
                          controller: _countryController,
                          label: 'users.country'.tr(),
                          icon: Icons.flag,
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: state is UserManagementLoading
                                ? null
                                : _submit,
                            icon: const Icon(Icons.person_add),
                            label: Text('users.create_user'.tr()),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                if (state is UserManagementLoading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black12,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequiredField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _RequiredField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: '$label *',
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

class _OptionalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _OptionalField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
