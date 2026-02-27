import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/assignment.dart';
import '../bloc/assignment_bloc.dart';

class AssignmentListPage extends StatelessWidget {
  final int courseId;

  const AssignmentListPage({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AssignmentBloc(repository: sl())
            ..add(LoadAssignments(courseId: courseId)),
      child: Scaffold(
        appBar: AppBar(title: Text('assignments.title'.tr())),
        body: BlocBuilder<AssignmentBloc, AssignmentState>(
          builder: (context, state) {
            if (state is AssignmentLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AssignmentError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<AssignmentBloc>().add(
                        LoadAssignments(courseId: courseId),
                      ),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }
            if (state is AssignmentsLoaded) {
              if (state.assignments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text('common.no_data'.tr()),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.assignments.length,
                itemBuilder: (context, index) =>
                    _AssignmentCard(assignment: state.assignments[index]),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueDate = assignment.dueDate != null
        ? DateTime.fromMillisecondsSinceEpoch(assignment.dueDate! * 1000)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.push(
            '/assignment/detail/${assignment.id}',
            extra: {'assignment': assignment},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      assignment.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (assignment.isOverdue)
                    Chip(
                      label: Text(
                        'assignments.not_submitted'.tr(),
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.red.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: Colors.red),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              if (dueDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${'assignments.due_date'.tr()}: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
