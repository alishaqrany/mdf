import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/course_model.dart';
import '../bloc/course_create_bloc.dart';

class CourseCreatePage extends StatefulWidget {
  const CourseCreatePage({super.key});

  @override
  State<CourseCreatePage> createState() => _CourseCreatePageState();
}

class _CourseCreatePageState extends State<CourseCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _summaryController = TextEditingController();
  final _numSectionsController = TextEditingController(text: '10');

  int? _selectedCategoryId;
  bool _visible = true;
  DateTime? _startDate;
  DateTime? _endDate;
  String _format = 'topics';

  final _formats = [
    ('topics', 'Topics format'),
    ('weeks', 'Weekly format'),
    ('social', 'Social format'),
    ('singleactivity', 'Single activity'),
  ];

  @override
  void initState() {
    super.initState();
    context.read<CourseCreateBloc>().add(LoadCategoriesForCreate());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _shortNameController.dispose();
    _summaryController.dispose();
    _numSectionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(tr('admin.create_course')), centerTitle: true),
      body: BlocConsumer<CourseCreateBloc, CourseCreateState>(
        listener: (context, state) {
          if (state is CourseCreateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tr('admin.course_created_success', args: [state.courseName]),
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.pop(true);
          } else if (state is CourseCreateError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CourseCreateLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<CourseCategoryModel> categories = [];
          if (state is CategoriesLoadedForCreate) {
            categories = state.categories;
            _selectedCategoryId ??= categories.isNotEmpty
                ? categories.first.id
                : null;
          }

          final isSubmitting = state is CourseCreateSubmitting;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Basic Info Card ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('admin.course_basic_info'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              labelText: tr('admin.course_full_name'),
                              prefixIcon: const Icon(Icons.school),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? tr('admin.field_required')
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _shortNameController,
                            decoration: InputDecoration(
                              labelText: tr('admin.course_short_name'),
                              prefixIcon: const Icon(Icons.label),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? tr('admin.field_required')
                                : null,
                          ),
                          const SizedBox(height: 12),
                          if (categories.isNotEmpty)
                            DropdownButtonFormField<int>(
                              value: _selectedCategoryId,
                              decoration: InputDecoration(
                                labelText: tr('admin.course_category'),
                                prefixIcon: const Icon(Icons.category),
                                border: const OutlineInputBorder(),
                              ),
                              items: categories.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategoryId = v),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Description Card ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('admin.course_description'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _summaryController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: tr('admin.course_summary'),
                              alignLabelWithHint: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Settings Card ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('admin.course_settings'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _format,
                            decoration: InputDecoration(
                              labelText: tr('admin.course_format'),
                              prefixIcon: const Icon(Icons.view_list),
                              border: const OutlineInputBorder(),
                            ),
                            items: _formats.map((f) {
                              return DropdownMenuItem(
                                value: f.$1,
                                child: Text(f.$2),
                              );
                            }).toList(),
                            onChanged: (v) =>
                                setState(() => _format = v ?? 'topics'),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _numSectionsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: tr('admin.course_num_sections'),
                              prefixIcon: const Icon(
                                Icons.format_list_numbered,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            title: Text(tr('admin.course_visible')),
                            subtitle: Text(tr('admin.course_visible_hint')),
                            value: _visible,
                            onChanged: (v) => setState(() => _visible = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Dates Card ───
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('admin.course_dates'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: const Icon(Icons.calendar_today),
                            title: Text(tr('admin.course_start_date')),
                            subtitle: Text(
                              _startDate != null
                                  ? DateFormat.yMMMd().format(_startDate!)
                                  : tr('admin.not_set'),
                            ),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _pickDate(isStart: true),
                          ),
                          ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(tr('admin.course_end_date')),
                            subtitle: Text(
                              _endDate != null
                                  ? DateFormat.yMMMd().format(_endDate!)
                                  : tr('admin.not_set'),
                            ),
                            trailing: const Icon(Icons.edit),
                            onTap: () => _pickDate(isStart: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Submit ───
                  FilledButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_circle),
                    label: Text(
                      isSubmitting
                          ? tr('admin.creating')
                          : tr('admin.create_course'),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 90)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr('admin.select_category'))));
      return;
    }

    context.read<CourseCreateBloc>().add(
      SubmitCourseCreate(
        fullName: _fullNameController.text.trim(),
        shortName: _shortNameController.text.trim(),
        categoryId: _selectedCategoryId!,
        summary: _summaryController.text.trim(),
        visible: _visible,
        startDate: _startDate,
        endDate: _endDate,
        format: _format,
        numSections: int.tryParse(_numSectionsController.text.trim()),
      ),
    );
  }
}
