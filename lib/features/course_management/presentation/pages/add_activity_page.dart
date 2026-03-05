import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../bloc/course_management_bloc.dart';
import '../bloc/course_management_event.dart';
import '../bloc/course_management_state.dart';

/// Page to add a new activity/resource to a course section.
class AddActivityPage extends StatelessWidget {
  final int courseId;
  final int sectionNum;
  final String sectionName;

  const AddActivityPage({
    super.key,
    required this.courseId,
    required this.sectionNum,
    this.sectionName = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CourseManagementBloc>(),
      child: _AddActivityView(
        courseId: courseId,
        sectionNum: sectionNum,
        sectionName: sectionName,
      ),
    );
  }
}

class _AddActivityView extends StatefulWidget {
  final int courseId;
  final int sectionNum;
  final String sectionName;

  const _AddActivityView({
    required this.courseId,
    required this.sectionNum,
    required this.sectionName,
  });

  @override
  State<_AddActivityView> createState() => _AddActivityViewState();
}

class _AddActivityViewState extends State<_AddActivityView> {
  String? _selectedType;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Assignment config
  final _dueDateController = TextEditingController();
  DateTime? _dueDate;
  int _maxGrade = 100;

  // Quiz config
  int _timeLimit = 0;

  // URL config
  final _urlController = TextEditingController();

  static const _activityTypes = [
    _ActivityType('resource', Icons.attach_file, 'course_mgmt.type_resource'),
    _ActivityType('page', Icons.article, 'course_mgmt.type_page'),
    _ActivityType('label', Icons.label, 'course_mgmt.type_label'),
    _ActivityType('assign', Icons.assignment, 'course_mgmt.type_assign'),
    _ActivityType('quiz', Icons.quiz, 'course_mgmt.type_quiz'),
    _ActivityType('forum', Icons.forum, 'course_mgmt.type_forum'),
    _ActivityType('url', Icons.link, 'course_mgmt.type_url'),
    _ActivityType('folder', Icons.folder, 'course_mgmt.type_folder'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _dueDateController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('course_mgmt.add_activity')),
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
        child: _selectedType == null
            ? _buildTypePicker(theme)
            : _buildForm(theme),
      ),
    );
  }

  Widget _buildTypePicker(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sectionName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${tr('course_mgmt.section')}: ${widget.sectionName}',
                style: theme.textTheme.titleMedium,
              ),
            ),
          Text(
            tr('course_mgmt.select_type'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _activityTypes.length,
              itemBuilder: (context, index) {
                final type = _activityTypes[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedType = type.key),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(type.icon, size: 40, color: theme.primaryColor),
                        const SizedBox(height: 8),
                        Text(
                          tr(type.labelKey),
                          style: theme.textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Back to type picker
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _selectedType = null),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(tr('course_mgmt.change_type')),
                ),
                const Spacer(),
                Chip(
                  label: Text(tr('course_mgmt.type_$_selectedType')),
                  avatar: Icon(
                    _activityTypes
                        .firstWhere((t) => t.key == _selectedType)
                        .icon,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name field
            if (_selectedType != 'label')
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: tr('course_mgmt.field_name'),
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? tr('common.required') : null,
              ),
            if (_selectedType != 'label') const SizedBox(height: 16),

            // Description/Intro field
            TextFormField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: _selectedType == 'label'
                    ? tr('course_mgmt.field_label_text')
                    : tr('course_mgmt.field_description'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: _selectedType == 'label'
                  ? (v) =>
                        (v == null || v.isEmpty) ? tr('common.required') : null
                  : null,
            ),
            const SizedBox(height: 16),

            // Type-specific fields
            ..._buildTypeSpecificFields(theme),

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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(tr('course_mgmt.add_activity')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeSpecificFields(ThemeData theme) {
    switch (_selectedType) {
      case 'assign':
        return [
          // Due date
          TextFormField(
            controller: _dueDateController,
            decoration: InputDecoration(
              labelText: tr('course_mgmt.field_due_date'),
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.calendar_today),
            ),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 23, minute: 59),
                );
                setState(() {
                  _dueDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time?.hour ?? 23,
                    time?.minute ?? 59,
                  );
                  _dueDateController.text = DateFormat(
                    'yyyy-MM-dd HH:mm',
                  ).format(_dueDate!);
                });
              }
            },
          ),
          const SizedBox(height: 16),
          // Max grade
          TextFormField(
            initialValue: _maxGrade.toString(),
            decoration: InputDecoration(
              labelText: tr('course_mgmt.field_max_grade'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => _maxGrade = int.tryParse(v) ?? 100,
          ),
        ];

      case 'quiz':
        return [
          TextFormField(
            initialValue: _timeLimit.toString(),
            decoration: InputDecoration(
              labelText: tr('course_mgmt.field_time_limit'),
              helperText: tr('course_mgmt.field_time_limit_help'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => _timeLimit = int.tryParse(v) ?? 0,
          ),
        ];

      case 'url':
        return [
          TextFormField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: tr('course_mgmt.field_url'),
              border: const OutlineInputBorder(),
              hintText: 'https://...',
            ),
            keyboardType: TextInputType.url,
            validator: (v) =>
                (v == null || v.isEmpty) ? tr('common.required') : null,
          ),
        ];

      default:
        return [];
    }
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    Map<String, dynamic>? config;
    switch (_selectedType) {
      case 'assign':
        config = {
          if (_dueDate != null)
            'duedate': (_dueDate!.millisecondsSinceEpoch ~/ 1000).toString(),
          'grade': _maxGrade.toString(),
        };
        break;
      case 'quiz':
        if (_timeLimit > 0) {
          config = {'timelimit': (_timeLimit * 60).toString()};
        }
        break;
      case 'url':
        config = {'externalurl': _urlController.text};
        break;
    }

    context.read<CourseManagementBloc>().add(
      AddModule(
        courseId: widget.courseId,
        sectionNum: widget.sectionNum,
        moduleName: _selectedType!,
        name: _selectedType == 'label'
            ? _descController.text
            : _nameController.text,
        intro: _descController.text,
        config: config,
      ),
    );
  }
}

class _ActivityType {
  final String key;
  final IconData icon;
  final String labelKey;

  const _ActivityType(this.key, this.icon, this.labelKey);
}
