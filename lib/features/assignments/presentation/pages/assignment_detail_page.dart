import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:image_picker/image_picker.dart' as img_picker;

import '../../../../app/di/injection.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../domain/entities/assignment.dart';
import '../bloc/assignment_bloc.dart';

/// Displays assignment details with submission form.
class AssignmentDetailPage extends StatefulWidget {
  final Assignment assignment;

  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  State<AssignmentDetailPage> createState() => _AssignmentDetailPageState();
}

class _AssignmentDetailPageState extends State<AssignmentDetailPage> {
  final _textController = TextEditingController();
  final List<File> _selectedFiles = [];
  int? _draftItemId;
  bool _isUploading = false;
  List<AssignmentSubmission> _submissions = [];
  List<AssignmentGrade> _grades = [];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );
    if (result == null) return;

    _uploadFiles(result.files.map((f) => f.path).whereType<String>().toList());
  }

  Future<void> _pickImage() async {
    final picker = img_picker.ImagePicker();
    final image = await picker.pickImage(
      source: img_picker.ImageSource.gallery,
    );
    if (image == null) return;

    _uploadFiles([image.path]);
  }

  Future<void> _uploadFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    setState(() => _isUploading = true);
    try {
      final apiClient = sl<MoodleApiClient>();
      for (final path in paths) {
        final file = File(path);
        final uploadResult = await apiClient.uploadFile(
          file: file,
          fileArea: 'draft',
          itemId: _draftItemId ?? 0,
        );
        if (uploadResult.isNotEmpty) {
          _draftItemId =
              (uploadResult.first as Map<String, dynamic>)['itemid'] as int?;
          _selectedFiles.add(file);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.assignment;
    final dueDate = a.dueDate != null
        ? DateTime.fromMillisecondsSinceEpoch(a.dueDate! * 1000)
        : null;

    return BlocProvider(
      create: (_) =>
          AssignmentBloc(repository: sl())
            ..add(LoadSubmissions(assignmentId: a.id)),
      child: Scaffold(
        appBar: AppBar(title: Text(a.name)),
        body: BlocConsumer<AssignmentBloc, AssignmentState>(
          listener: (context, state) {
            if (state is AssignmentSubmitted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('assignments.submitted'.tr())),
              );
            }
            if (state is SubmissionsLoaded) {
              _submissions = state.submissions;
              // Load grades after submissions
              context.read<AssignmentBloc>().add(LoadGrades(assignmentId: a.id));
            }
            if (state is AssignmentGradesLoaded) {
              setState(() => _grades = state.grades);
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Intro / description
                  if (a.intro != null && a.intro!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: HtmlWidget(a.intro!),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Info card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (dueDate != null)
                            _Row(
                              'assignments.due_date'.tr(),
                              '${dueDate.day}/${dueDate.month}/${dueDate.year} ${dueDate.hour}:${dueDate.minute.toString().padLeft(2, '0')}',
                            ),
                          if (a.grade != null)
                            _Row('grades.grade'.tr(), '${a.grade}'),
                          if (a.maxAttempts != null && a.maxAttempts! > 0)
                            _Row('quiz.attempts'.tr(), '${a.maxAttempts}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submission status
                  if (_submissions.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'assignments.submission_status'.tr(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._submissions.map(
                              (s) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  s.isSubmitted
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: s.isSubmitted
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                title: Text(
                                  s.isSubmitted
                                      ? 'assignments.submitted'.tr()
                                      : 'assignments.not_submitted'.tr(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Grade / Feedback section
                  if (_grades.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.grade, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  'grades.grade'.tr(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._grades.map((g) {
                              final gradeDate = g.timeModified != null
                                  ? DateTime.fromMillisecondsSinceEpoch(g.timeModified! * 1000)
                                  : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _Row(
                                    'grades.grade'.tr(),
                                    g.grade != null
                                        ? '${g.grade!.toStringAsFixed(1)} / ${a.grade ?? '-'}'
                                        : '-',
                                  ),
                                  if (g.grade != null && a.grade != null && a.grade! > 0)
                                    _Row(
                                      'grades.percentage'.tr(),
                                      '${((g.grade! / a.grade!) * 100).toStringAsFixed(0)}%',
                                    ),
                                  if (gradeDate != null)
                                    _Row(
                                      'grades.graded_on'.tr(),
                                      '${gradeDate.day}/${gradeDate.month}/${gradeDate.year}',
                                    ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Submission form
                  Text(
                    'assignments.submit_assignment'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'assignments.add_text'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // File upload buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickFiles,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.attach_file),
                          label: Text('assignments.upload_file'.tr()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.image),
                          label: Text('assignments.upload_image'.tr()),
                        ),
                      ),
                    ],
                  ),

                  // Selected files list
                  if (_selectedFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._selectedFiles.asMap().entries.map(
                      (entry) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.insert_drive_file, size: 20),
                        title: Text(
                          entry.value.path.split(Platform.pathSeparator).last,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedFiles.removeAt(entry.key);
                            });
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state is AssignmentLoading
                          ? null
                          : () {
                              final text = _textController.text.trim();
                              context.read<AssignmentBloc>().add(
                                SaveAssignmentSubmission(
                                  assignmentId: a.id,
                                  onlineText: text.isNotEmpty ? text : null,
                                  fileItemId: _draftItemId,
                                ),
                              );
                            },
                      icon: const Icon(Icons.send),
                      label: Text('assignments.submit_assignment'.tr()),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
