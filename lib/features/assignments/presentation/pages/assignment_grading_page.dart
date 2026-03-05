import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/assignment.dart';
import '../bloc/assignment_bloc.dart';

/// Page for teachers/admins to view submissions and grade assignments.
class AssignmentGradingPage extends StatefulWidget {
  final int assignmentId;
  final String assignmentName;
  final int? maxGrade;

  const AssignmentGradingPage({
    super.key,
    required this.assignmentId,
    required this.assignmentName,
    this.maxGrade,
  });

  @override
  State<AssignmentGradingPage> createState() => _AssignmentGradingPageState();
}

class _AssignmentGradingPageState extends State<AssignmentGradingPage> {
  late final AssignmentBloc _bloc;
  List<AssignmentSubmission> _submissions = [];
  List<AssignmentGrade> _existingGrades = [];
  bool _showOnlyNeedsGrading = false;

  @override
  void initState() {
    super.initState();
    _bloc = AssignmentBloc(repository: sl());
    _bloc.add(LoadSubmissions(assignmentId: widget.assignmentId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  List<AssignmentSubmission> get _filteredSubmissions {
    if (!_showOnlyNeedsGrading) return _submissions;
    final gradedUserIds =
        _existingGrades.map((g) => g.userId).toSet();
    return _submissions
        .where((s) => s.isSubmitted && !gradedUserIds.contains(s.userId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.assignmentName),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(tr('grading.all_submissions')),
                    selected: !_showOnlyNeedsGrading,
                    onSelected: (_) =>
                        setState(() => _showOnlyNeedsGrading = false),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(tr('grading.needs_grading')),
                    selected: _showOnlyNeedsGrading,
                    onSelected: (_) =>
                        setState(() => _showOnlyNeedsGrading = true),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: BlocConsumer<AssignmentBloc, AssignmentState>(
          listener: (context, state) {
            if (state is SubmissionsLoaded) {
              setState(() => _submissions = state.submissions);
              // Also load grades to detect which ones are already graded
              _bloc.add(LoadGrades(assignmentId: widget.assignmentId));
            } else if (state is AssignmentGradesLoaded) {
              setState(() => _existingGrades = state.grades);
            } else if (state is GradeSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('grading.grade_saved')),
                  backgroundColor: AppColors.success,
                ),
              );
              // Reload
              _bloc.add(LoadSubmissions(assignmentId: widget.assignmentId));
            } else if (state is AssignmentError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AssignmentLoading && _submissions.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final filtered = _filteredSubmissions;
            if (filtered.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('grading.no_submissions'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _SubmissionCard(
                  submission: filtered[index],
                  existingGrade: _existingGrades
                      .where((g) => g.userId == filtered[index].userId)
                      .firstOrNull,
                  maxGrade: widget.maxGrade ?? 100,
                  onSaveGrade: (userId, grade, feedback) {
                    _bloc.add(SaveGradeEvent(
                      assignmentId: widget.assignmentId,
                      userId: userId,
                      grade: grade,
                      feedback: feedback,
                    ));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatefulWidget {
  final AssignmentSubmission submission;
  final AssignmentGrade? existingGrade;
  final int maxGrade;
  final void Function(int userId, double grade, String? feedback) onSaveGrade;

  const _SubmissionCard({
    required this.submission,
    required this.existingGrade,
    required this.maxGrade,
    required this.onSaveGrade,
  });

  @override
  State<_SubmissionCard> createState() => _SubmissionCardState();
}

class _SubmissionCardState extends State<_SubmissionCard> {
  late final TextEditingController _gradeController;
  late final TextEditingController _feedbackController;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(
      text: widget.existingGrade?.grade?.toStringAsFixed(1) ?? '',
    );
    _feedbackController = TextEditingController();
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sub = widget.submission;
    final isGraded = widget.existingGrade != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: sub.isSubmitted
                  ? (isGraded ? AppColors.success : AppColors.warning)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Icon(
                isGraded
                    ? Icons.check_circle
                    : (sub.isSubmitted
                        ? Icons.assignment_returned
                        : Icons.assignment_late),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              '${tr('grading.student')} #${sub.userId}',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              sub.isSubmitted
                  ? (isGraded ? tr('grading.graded') : tr('grading.submitted'))
                  : tr('grading.not_submitted'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: sub.isSubmitted
                    ? (isGraded ? AppColors.success : AppColors.warning)
                    : AppColors.error,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGraded)
                  Chip(
                    label: Text(
                      '${widget.existingGrade!.grade?.toStringAsFixed(1) ?? '-'}/${widget.maxGrade}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.success,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                if (sub.isSubmitted)
                  IconButton(
                    icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
              ],
            ),
          ),
          if (_expanded && sub.isSubmitted) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sub.timeModified != null)
                    Text(
                      '${tr('grading.submitted_on')}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.fromMillisecondsSinceEpoch(sub.timeModified! * 1000))}',
                      style: theme.textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  // Grade input
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _gradeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: tr('grading.grade_label'),
                            suffixText: '/ ${widget.maxGrade}',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _feedbackController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: tr('grading.feedback'),
                            hintText: tr('grading.feedback_hint'),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.icon(
                      onPressed: () {
                        final grade =
                            double.tryParse(_gradeController.text.trim());
                        if (grade == null ||
                            grade < 0 ||
                            grade > widget.maxGrade) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr('grading.invalid_grade')),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        widget.onSaveGrade(
                          sub.userId,
                          grade,
                          _feedbackController.text.trim().isNotEmpty
                              ? _feedbackController.text.trim()
                              : null,
                        );
                      },
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(tr('grading.save_grade')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
