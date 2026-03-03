import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../data/models/course_visibility_model.dart';
import '../bloc/course_visibility_bloc.dart';

/// Admin page for managing course visibility (hide/show courses for users, cohorts, or all).
class CourseVisibilityPage extends StatelessWidget {
  const CourseVisibilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CourseVisibilityBloc(apiClient: GetIt.instance<MoodleApiClient>())
            ..add(const LoadCourseVisibility()),
      child: const _CourseVisibilityView(),
    );
  }
}

class _CourseVisibilityView extends StatelessWidget {
  const _CourseVisibilityView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('course_visibility.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: tr('course_visibility.add_override'),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<CourseVisibilityBloc, CourseVisibilityState>(
        listener: (context, state) {
          if (state is CourseVisibilityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CourseVisibilityLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CourseVisibilityLoaded) {
            if (state.overrides.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('course_visibility.no_overrides'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showAddDialog(context),
                      icon: const Icon(Icons.add),
                      label: Text(tr('course_visibility.add_override')),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CourseVisibilityBloc>().add(
                  const LoadCourseVisibility(),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.overrides.length,
                itemBuilder: (context, index) {
                  final overrideItem = state.overrides[index];
                  return _OverrideCard(item: overrideItem);
                },
              ),
            );
          }
          if (state is CourseVisibilityError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<CourseVisibilityBloc>().add(
                      const LoadCourseVisibility(),
                    ),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CourseVisibilityBloc>(),
        child: const _AddOverrideSheet(),
      ),
    );
  }
}

// ─── Override Card Widget ───
class _OverrideCard extends StatelessWidget {
  final CourseVisibilityOverride item;
  const _OverrideCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetLabel = _targetLabel(item);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: item.hidden
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            item.hidden
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            color: item.hidden
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(item.coursename, style: theme.textTheme.titleSmall),
        subtitle: Text(targetLabel, style: theme.textTheme.bodySmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle visibility
            IconButton(
              icon: Icon(
                item.hidden
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
              tooltip: item.hidden
                  ? tr('course_visibility.show')
                  : tr('course_visibility.hide'),
              onPressed: () {
                context.read<CourseVisibilityBloc>().add(
                  SetCourseVisibilityEvent(
                    courseid: item.courseid,
                    targettype: item.targettype,
                    targetid: item.targetid,
                    hidden: item.hidden ? 0 : 1,
                  ),
                );
              },
            ),
            // Delete
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              tooltip: tr('common.delete'),
              onPressed: () {
                _confirmDelete(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(CourseVisibilityOverride o) {
    switch (o.targettype) {
      case 'all':
        return tr('course_visibility.target_all');
      case 'user':
        return '${tr('course_visibility.target_user')}: ${o.targetname}';
      case 'cohort':
        return '${tr('course_visibility.target_cohort')}: ${o.targetname}';
      default:
        return o.targettype;
    }
  }

  void _confirmDelete(BuildContext context, CourseVisibilityOverride override) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('course_visibility.delete_title')),
        content: Text(tr('course_visibility.delete_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CourseVisibilityBloc>().add(
                RemoveCourseVisibilityEvent(id: override.id),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
  }
}

// ─── Add Override Bottom Sheet ───
class _AddOverrideSheet extends StatefulWidget {
  const _AddOverrideSheet();

  @override
  State<_AddOverrideSheet> createState() => _AddOverrideSheetState();
}

class _AddOverrideSheetState extends State<_AddOverrideSheet> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCourseId;
  String? _selectedCourseName;
  String _targetType = 'all';
  int _targetId = 0;
  String? _targetName;
  bool _isLoadingCourses = false;
  bool _isLoadingTargets = false;
  List<Map<String, dynamic>> _courses = [];
  List<Map<String, dynamic>> _targets = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final apiClient = GetIt.instance<MoodleApiClient>();
      final response = await apiClient.call(MoodleApiEndpoints.getCourses);
      if (response is List) {
        setState(() {
          _courses = response
              .cast<Map<String, dynamic>>()
              .where((c) => (c['id'] as int?) != 1) // Skip site course
              .toList();
        });
      }
    } catch (_) {}
    setState(() => _isLoadingCourses = false);
  }

  Future<void> _loadTargets() async {
    if (_targetType == 'all') {
      setState(() {
        _targets = [];
        _targetId = 0;
      });
      return;
    }
    setState(() => _isLoadingTargets = true);
    try {
      final apiClient = GetIt.instance<MoodleApiClient>();

      if (_targetType == 'user') {
        final response = await apiClient.call(
          MoodleApiEndpoints.getUsers,
          params: {'criteria[0][key]': 'email', 'criteria[0][value]': '%'},
        );
        if (response is Map && response.containsKey('users')) {
          setState(() {
            _targets = (response['users'] as List)
                .cast<Map<String, dynamic>>()
                .map(
                  (u) => {
                    'id': u['id'],
                    'name': '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'
                        .trim(),
                  },
                )
                .toList();
          });
        }
      } else if (_targetType == 'cohort') {
        final response = await apiClient.call(MoodleApiEndpoints.mdfGetCohorts);
        if (response is Map && response.containsKey('cohorts')) {
          setState(() {
            _targets = (response['cohorts'] as List)
                .cast<Map<String, dynamic>>()
                .map((c) => {'id': c['id'], 'name': c['name'] ?? ''})
                .toList();
          });
        }
      }
    } catch (_) {}
    setState(() => _isLoadingTargets = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('course_visibility.add_override'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // Course selector
              Text(
                tr('course_visibility.select_course'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (_isLoadingCourses)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<int>(
                  value: _selectedCourseId,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: tr('course_visibility.select_course'),
                  ),
                  items: _courses.map((c) {
                    return DropdownMenuItem<int>(
                      value: c['id'] as int,
                      child: Text(
                        c['fullname'] as String? ??
                            c['shortname'] as String? ??
                            'Course ${c['id']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCourseId = value;
                      final course = _courses.firstWhere(
                        (c) => c['id'] == value,
                        orElse: () => {},
                      );
                      _selectedCourseName = course['fullname'] as String? ?? '';
                    });
                  },
                  validator: (value) =>
                      value == null ? tr('common.required') : null,
                ),

              const SizedBox(height: 16),

              // Target type
              Text(
                tr('course_visibility.target_type'),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'all',
                    label: Text(tr('course_visibility.target_all')),
                    icon: const Icon(Icons.public),
                  ),
                  ButtonSegment(
                    value: 'user',
                    label: Text(tr('course_visibility.target_user')),
                    icon: const Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: 'cohort',
                    label: Text(tr('course_visibility.target_cohort')),
                    icon: const Icon(Icons.group),
                  ),
                ],
                selected: {_targetType},
                onSelectionChanged: (value) {
                  setState(() {
                    _targetType = value.first;
                    _targetId = 0;
                    _targetName = null;
                  });
                  _loadTargets();
                },
              ),

              // Target selector (user or cohort)
              if (_targetType != 'all') ...[
                const SizedBox(height: 16),
                Text(
                  _targetType == 'user'
                      ? tr('course_visibility.select_user')
                      : tr('course_visibility.select_cohort'),
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                if (_isLoadingTargets)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<int>(
                    value: _targetId > 0 ? _targetId : null,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: _targetType == 'user'
                          ? tr('course_visibility.select_user')
                          : tr('course_visibility.select_cohort'),
                    ),
                    items: _targets.map((t) {
                      return DropdownMenuItem<int>(
                        value: t['id'] as int,
                        child: Text(
                          t['name'] as String? ?? 'ID: ${t['id']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _targetId = value ?? 0;
                        final target = _targets.firstWhere(
                          (t) => t['id'] == value,
                          orElse: () => {},
                        );
                        _targetName = target['name'] as String?;
                      });
                    },
                    validator: (value) =>
                        value == null ? tr('common.required') : null,
                  ),
              ],

              const SizedBox(height: 24),

              // Submit
              FilledButton.icon(
                onPressed: () {
                  if (_formKey.currentState?.validate() ?? false) {
                    context.read<CourseVisibilityBloc>().add(
                      SetCourseVisibilityEvent(
                        courseid: _selectedCourseId!,
                        targettype: _targetType,
                        targetid: _targetId,
                        hidden: 1,
                      ),
                    );
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.visibility_off_rounded),
                label: Text(tr('course_visibility.hide_course')),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
