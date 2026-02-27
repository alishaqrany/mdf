import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../app/di/injection.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
                  if (state is SubmissionsLoaded &&
                      state.submissions.isNotEmpty)
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
                            ...state.submissions.map(
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
