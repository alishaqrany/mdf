import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../features/courses/domain/entities/course.dart';
import '../../../../features/courses/domain/repositories/courses_repository.dart';
import '../../domain/entities/protection_settings.dart';
import '../bloc/content_protection_bloc.dart';

/// Admin panel for managing content protection settings.
class ContentProtectionAdminPage extends StatefulWidget {
  const ContentProtectionAdminPage({super.key});

  @override
  State<ContentProtectionAdminPage> createState() =>
      _ContentProtectionAdminPageState();
}

class _ContentProtectionAdminPageState
    extends State<ContentProtectionAdminPage> {
  late ProtectionSettings _settings;
  bool _loaded = false;
  final _courseIdController = TextEditingController();

  // Content type options
  static const _contentTypes = [
    'resource',
    'url',
    'page',
    'book',
    'folder',
    'quiz',
    'assign',
    'scorm',
    'h5pactivity',
    'lesson',
    'video',
    'label',
  ];

  List<Course>? _allCourses;
  int? _selectedCourseIdToAdd;

  @override
  void initState() {
    super.initState();
    _loadAllCourses();
  }

  Future<void> _loadAllCourses() async {
    final coursesRepo = sl<CoursesRepository>();
    final result = await coursesRepo.getAllCourses();
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _allCourses = [],
          (courses) => _allCourses = courses,
        );
        _allCourses?.removeWhere((c) => c.fullName.trim().isEmpty);
      });
    }
  }

  @override
  void dispose() {
    _courseIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return BlocProvider(
      create: (_) => sl<ContentProtectionBloc>()..add(LoadProtectionSettings()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('content_protection.title'.tr()),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'content_protection.view_log'.tr(),
              onPressed: () => context.pushNamed('protection-log'),
            ),
          ],
        ),
        body: BlocConsumer<ContentProtectionBloc, ContentProtectionState>(
          listener: (context, state) {
            if (state is ProtectionSettingsLoaded) {
              setState(() {
                _settings = state.settings;
                _loaded = true;
              });
            }
            if (state is ProtectionSettingsSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('content_protection.settings_saved'.tr()),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (state is ContentProtectionError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: cs.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (!_loaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Master Switch ───
                  _buildSectionCard(
                    theme: theme,
                    title: 'content_protection.master_switch'.tr(),
                    icon: Icons.shield,
                    iconColor: _settings.enabled ? Colors.green : cs.outline,
                    children: [
                      SwitchListTile(
                        title: Text(
                          'content_protection.enable_protection'.tr(),
                        ),
                        subtitle: Text(
                          'content_protection.enable_protection_desc'.tr(),
                        ),
                        value: _settings.enabled,
                        onChanged: (v) => setState(
                          () => _settings = _settings.copyWith(enabled: v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Protection Features ───
                  _buildSectionCard(
                    theme: theme,
                    title: 'content_protection.features'.tr(),
                    icon: Icons.security,
                    children: [
                      SwitchListTile(
                        title: Text(
                          'content_protection.prevent_screenshot'.tr(),
                        ),
                        subtitle: Text(
                          'content_protection.prevent_screenshot_desc'.tr(),
                        ),
                        value: _settings.preventScreenCapture,
                        onChanged: _settings.enabled
                            ? (v) => setState(
                                () => _settings = _settings.copyWith(
                                  preventScreenCapture: v,
                                ),
                              )
                            : null,
                      ),
                      SwitchListTile(
                        title: Text(
                          'content_protection.prevent_recording'.tr(),
                        ),
                        subtitle: Text(
                          'content_protection.prevent_recording_desc'.tr(),
                        ),
                        value: _settings.preventScreenRecording,
                        onChanged: _settings.enabled
                            ? (v) => setState(
                                () => _settings = _settings.copyWith(
                                  preventScreenRecording: v,
                                ),
                              )
                            : null,
                      ),
                      SwitchListTile(
                        title: Text('content_protection.watermark'.tr()),
                        subtitle: Text(
                          'content_protection.watermark_desc'.tr(),
                        ),
                        value: _settings.watermarkEnabled,
                        onChanged: _settings.enabled
                            ? (v) => setState(
                                () => _settings = _settings.copyWith(
                                  watermarkEnabled: v,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Device Limit ───
                  _buildSectionCard(
                    theme: theme,
                    title: 'content_protection.device_limit'.tr(),
                    icon: Icons.devices,
                    children: [
                      ListTile(
                        title: Text(
                          'content_protection.default_max_devices'.tr(),
                        ),
                        subtitle: Text(
                          'content_protection.default_max_devices_desc'.tr(),
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: DropdownButtonFormField<int>(
                            value: _settings.defaultMaxDevices.clamp(1, 10),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            items: List.generate(10, (i) => i + 1)
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v'),
                                  ),
                                )
                                .toList(),
                            onChanged: _settings.enabled
                                ? (v) => setState(
                                    () => _settings = _settings.copyWith(
                                      defaultMaxDevices: v,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: Text(
                          'content_protection.manage_user_devices'.tr(),
                        ),
                        subtitle: Text(
                          'content_protection.manage_user_devices_desc'.tr(),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.pushNamed('device-management'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Protected Courses ───
                  _buildSectionCard(
                    theme: theme,
                    title: 'content_protection.protected_courses'.tr(),
                    icon: Icons.school,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          _settings.isAllCourses
                              ? 'content_protection.all_courses_protected'.tr()
                              : 'content_protection.specific_courses_protected'
                                    .tr(
                                      args: [
                                        '${_settings.protectedCourseIds.length}',
                                      ],
                                    ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (_settings.protectedCourseIds.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: _settings.protectedCourseIds
                                .map(
                                  (id) => Chip(
                                    label: Text(
                                      'content_protection.course_id'.tr(
                                        args: ['$id'],
                                      ),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                    ),
                                    onDeleted: _settings.enabled
                                        ? () {
                                            final ids = List<int>.from(
                                              _settings.protectedCourseIds,
                                            )..remove(id);
                                            setState(
                                              () => _settings = _settings
                                                  .copyWith(
                                                    protectedCourseIds: ids,
                                                  ),
                                            );
                                          }
                                        : null,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _allCourses == null
                                  ? const Center(child: CircularProgressIndicator())
                                  : DropdownButtonFormField<int>(
                                      value: _selectedCourseIdToAdd,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        labelText: 'content_protection.add_course_id'.tr(),
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: _allCourses!.map((course) {
                                        return DropdownMenuItem<int>(
                                          value: course.id,
                                          child: Text(course.fullName),
                                        );
                                      }).toList(),
                                      onChanged: _settings.enabled ? (val) {
                                        setState(() => _selectedCourseIdToAdd = val);
                                      } : null,
                                    ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.add),
                              onPressed: _settings.enabled
                                  ? () {
                                      final id = _selectedCourseIdToAdd;
                                      if (id != null && id > 0) {
                                        final ids = List<int>.from(
                                          _settings.protectedCourseIds,
                                        );
                                        if (!ids.contains(id)) {
                                          ids.add(id);
                                          setState(() {
                                            _settings = _settings.copyWith(
                                              protectedCourseIds: ids,
                                            );
                                            _selectedCourseIdToAdd = null;
                                          });
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.select_all, size: 18),
                              label: Text(
                                'content_protection.protect_all_courses'.tr(),
                              ),
                              onPressed: _settings.enabled
                                  ? () => setState(
                                      () => _settings = _settings.copyWith(
                                        protectedCourseIds: [],
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ─── Protected Content Types ───
                  _buildSectionCard(
                    theme: theme,
                    title: 'content_protection.content_types'.tr(),
                    icon: Icons.category,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          _settings.isAllContentTypes
                              ? 'content_protection.all_types_protected'.tr()
                              : 'content_protection.specific_types_protected'.tr(
                                  args: [
                                    '${_settings.protectedContentTypes.length}',
                                  ],
                                ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _contentTypes.map((type) {
                            final selected =
                                _settings.isAllContentTypes ||
                                _settings.protectedContentTypes.contains(type);
                            return FilterChip(
                              label: Text(type),
                              selected: selected,
                              onSelected: _settings.enabled
                                  ? (v) {
                                      List<String> types;
                                      if (_settings.isAllContentTypes) {
                                        // Switching from all → specific: select all minus this
                                        types = List.from(_contentTypes)
                                          ..remove(type);
                                      } else if (v) {
                                        types = List<String>.from(
                                          _settings.protectedContentTypes,
                                        )..add(type);
                                        // If all selected, switch to empty (= all)
                                        if (types.length ==
                                            _contentTypes.length) {
                                          types = [];
                                        }
                                      } else {
                                        types = List<String>.from(
                                          _settings.protectedContentTypes,
                                        )..remove(type);
                                      }
                                      setState(
                                        () => _settings = _settings.copyWith(
                                          protectedContentTypes: types,
                                        ),
                                      );
                                    }
                                  : null,
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ─── Save Button ───
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text('content_protection.save_settings'.tr()),
                      onPressed: () {
                        context.read<ContentProtectionBloc>().add(
                          SaveProtectionSettings(settings: _settings),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required ThemeData theme,
    required String title,
    required IconData icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
