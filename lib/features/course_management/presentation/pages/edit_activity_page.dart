import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../bloc/course_management_bloc.dart';
import '../bloc/course_management_event.dart';
import '../bloc/course_management_state.dart';

/// Page to edit an existing activity/resource module.
class EditActivityPage extends StatelessWidget {
  final int cmid;
  final String moduleName; // resource, page, label, assign, quiz, forum, url
  final String currentName;
  final String? currentIntro;
  final bool isVisible;

  const EditActivityPage({
    super.key,
    required this.cmid,
    required this.moduleName,
    required this.currentName,
    this.currentIntro,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CourseManagementBloc>(),
      child: _EditActivityView(
        cmid: cmid,
        moduleName: moduleName,
        currentName: currentName,
        currentIntro: currentIntro,
        isVisible: isVisible,
      ),
    );
  }
}

class _EditActivityView extends StatefulWidget {
  final int cmid;
  final String moduleName;
  final String currentName;
  final String? currentIntro;
  final bool isVisible;

  const _EditActivityView({
    required this.cmid,
    required this.moduleName,
    required this.currentName,
    this.currentIntro,
    required this.isVisible,
  });

  @override
  State<_EditActivityView> createState() => _EditActivityViewState();
}

class _EditActivityViewState extends State<_EditActivityView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late bool _isVisible;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descController = TextEditingController(text: widget.currentIntro ?? '');
    _isVisible = widget.isVisible;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('course_mgmt.edit_activity')),
        centerTitle: true,
        actions: [
          // Delete button
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: tr('common.delete'),
          ),
        ],
      ),
      body: BlocListener<CourseManagementBloc, CourseManagementState>(
        listener: (context, state) {
          if (state is CourseManagementSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pop(true);
          } else if (state is CourseManagementError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Module type indicator
                Card(
                  child: ListTile(
                    leading: Icon(_getModuleIcon(), color: theme.primaryColor),
                    title: Text(tr('course_mgmt.type_${widget.moduleName}')),
                    subtitle: Text('ID: ${widget.cmid}'),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: tr('course_mgmt.field_name'),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? tr('common.required') : null,
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: tr('course_mgmt.field_description'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Visibility toggle
                SwitchListTile(
                  title: Text(tr('course_mgmt.field_visible')),
                  subtitle: Text(
                    _isVisible
                        ? tr('course_mgmt.visible_yes')
                        : tr('course_mgmt.visible_no'),
                  ),
                  value: _isVisible,
                  onChanged: (v) => setState(() => _isVisible = v),
                ),
                const SizedBox(height: 24),

                // Submit button
                BlocBuilder<CourseManagementBloc, CourseManagementState>(
                  builder: (context, state) {
                    final isLoading = state is CourseManagementLoading;
                    return FilledButton.icon(
                      onPressed: isLoading ? null : _onSubmit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(tr('common.save')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getModuleIcon() {
    switch (widget.moduleName) {
      case 'resource':
        return Icons.attach_file;
      case 'page':
        return Icons.article;
      case 'label':
        return Icons.label;
      case 'assign':
        return Icons.assignment;
      case 'quiz':
        return Icons.quiz;
      case 'forum':
        return Icons.forum;
      case 'url':
        return Icons.link;
      case 'folder':
        return Icons.folder;
      default:
        return Icons.extension;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('course_mgmt.delete_confirm_title')),
        content: Text(tr('course_mgmt.delete_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CourseManagementBloc>().add(
                    DeleteModule(cmid: widget.cmid),
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<CourseManagementBloc>().add(UpdateModule(
          cmid: widget.cmid,
          name: _nameController.text,
          intro: _descController.text,
          visible: _isVisible ? 1 : 0,
        ));
  }
}
