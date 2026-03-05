import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../bloc/course_management_bloc.dart';
import '../bloc/course_management_event.dart';
import '../bloc/course_management_state.dart';

/// Dialog / bottom sheet to manage course sections.
class ManageSectionsPage extends StatelessWidget {
  final int courseId;

  const ManageSectionsPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CourseManagementBloc>(),
      child: _ManageSectionsView(courseId: courseId),
    );
  }
}

class _ManageSectionsView extends StatefulWidget {
  final int courseId;

  const _ManageSectionsView({required this.courseId});

  @override
  State<_ManageSectionsView> createState() => _ManageSectionsViewState();
}

class _ManageSectionsViewState extends State<_ManageSectionsView> {
  final _nameController = TextEditingController();
  final _summaryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('course_mgmt.add_section')),
        centerTitle: true,
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr('course_mgmt.field_section_name'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration: InputDecoration(
                  labelText: tr('course_mgmt.field_section_summary'),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              BlocBuilder<CourseManagementBloc, CourseManagementState>(
                builder: (context, state) {
                  final isLoading = state is CourseManagementLoading;
                  return FilledButton.icon(
                    onPressed: isLoading ? null : _onSubmit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: Text(tr('course_mgmt.add_section')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSubmit() {
    if (_nameController.text.isEmpty) return;
    context.read<CourseManagementBloc>().add(AddSection(
          courseId: widget.courseId,
          name: _nameController.text,
          summary: _summaryController.text.isNotEmpty
              ? _summaryController.text
              : null,
        ));
  }
}

/// A helper to show the edit section dialog
Future<bool?> showEditSectionDialog(
  BuildContext context, {
  required int sectionId,
  required String currentName,
  String? currentSummary,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => BlocProvider(
      create: (_) => sl<CourseManagementBloc>(),
      child: _EditSectionDialog(
        sectionId: sectionId,
        currentName: currentName,
        currentSummary: currentSummary,
      ),
    ),
  );
}

class _EditSectionDialog extends StatefulWidget {
  final int sectionId;
  final String currentName;
  final String? currentSummary;

  const _EditSectionDialog({
    required this.sectionId,
    required this.currentName,
    this.currentSummary,
  });

  @override
  State<_EditSectionDialog> createState() => _EditSectionDialogState();
}

class _EditSectionDialogState extends State<_EditSectionDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _summaryController =
        TextEditingController(text: widget.currentSummary ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CourseManagementBloc, CourseManagementState>(
      listener: (context, state) {
        if (state is CourseManagementSuccess) {
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
      child: AlertDialog(
        title: Text(tr('course_mgmt.edit_section')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: tr('course_mgmt.field_section_name'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              decoration: InputDecoration(
                labelText: tr('course_mgmt.field_section_summary'),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('common.cancel')),
          ),
          BlocBuilder<CourseManagementBloc, CourseManagementState>(
            builder: (context, state) {
              return FilledButton(
                onPressed: state is CourseManagementLoading
                    ? null
                    : () {
                        context.read<CourseManagementBloc>().add(
                              UpdateSection(
                                sectionId: widget.sectionId,
                                name: _nameController.text,
                                summary: _summaryController.text,
                              ),
                            );
                      },
                child: Text(tr('common.save')),
              );
            },
          ),
        ],
      ),
    );
  }
}
