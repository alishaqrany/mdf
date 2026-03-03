import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/grade.dart';
import '../bloc/grades_bloc.dart';

/// Grades overview page. Shows course-level grades with chart,
/// or per-course grade items with detail view.
class GradesPage extends StatelessWidget {
  final int? courseId;
  final int userId;

  const GradesPage({super.key, this.courseId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = GradesBloc(repository: sl());
        if (courseId != null) {
          bloc.add(LoadCourseGradeItems(courseId: courseId!, userId: userId));
        } else {
          bloc.add(LoadAllCourseGrades(userId: userId));
        }
        return bloc;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('grades.title'.tr())),
        body: BlocBuilder<GradesBloc, GradesState>(
          builder: (context, state) {
            if (state is GradesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is GradesError) {
              return Center(child: Text(state.message));
            }
            if (state is CourseGradesLoaded) {
              return _CourseGradesList(grades: state.grades);
            }
            if (state is GradeItemsLoaded) {
              return _GradeItemsList(items: state.items);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _CourseGradesList extends StatelessWidget {
  final List<CourseGrade> grades;

  const _CourseGradesList({required this.grades});

  @override
  Widget build(BuildContext context) {
    if (grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grade_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('grades.no_grades'.tr()),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grade chart
          if (grades.where((g) => g.grade != null).isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < grades.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                grades[idx].courseName.length > 8
                                    ? '${grades[idx].courseName.substring(0, 8)}…'
                                    : grades[idx].courseName,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: grades.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.grade ?? 0,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Grade list
          ...grades.map(
            (g) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Text(
                    g.grade != null ? '${g.grade!.round()}' : '-',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(g.courseName),
                subtitle: g.grade != null
                    ? Text('${g.grade!.toStringAsFixed(1)}%')
                    : Text('grades.no_grades'.tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeItemsList extends StatelessWidget {
  final List<GradeItem> items;

  const _GradeItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('grades.no_grades'.tr()));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final hasGrade = item.gradeRaw != null;
        final percentage = item.percentageFormatted;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => _showGradeDetail(context, item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Grade circle
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasGrade
                          ? _gradeColor(percentage).withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: hasGrade
                          ? Text(
                              item.gradeRaw!.toStringAsFixed(0),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _gradeColor(percentage),
                                  ),
                            )
                          : Icon(Icons.remove, color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (item.itemModule != null) ...[
                              Icon(
                                _moduleIcon(item.itemModule!),
                                size: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.itemModule!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                    ),
                              ),
                            ],
                            if (item.gradeDateGraded != null) ...[
                              if (item.itemModule != null)
                                const SizedBox(width: 8),
                              const Icon(
                                Icons.event,
                                size: 12,
                                color: AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                item.gradeDateGraded!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondaryLight,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        // Percentage bar
                        if (percentage != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (percentage / 100).clamp(0.0, 1.0),
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                      _gradeColor(percentage),
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${percentage.toStringAsFixed(0)}%',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _gradeColor(percentage),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Max grade
                  if (item.gradeMax != null)
                    Column(
                      children: [
                        Text(
                          '/ ${item.gradeMax!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondaryLight),
                        ),
                      ],
                    ),
                  const SizedBox(width: 4),
                  if (item.feedback != null && item.feedback!.isNotEmpty)
                    Icon(
                      Icons.comment,
                      size: 16,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _gradeColor(double? percentage) {
    if (percentage == null) return Colors.grey;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _moduleIcon(String module) {
    switch (module) {
      case 'quiz':
        return Icons.quiz_outlined;
      case 'assign':
        return Icons.assignment_outlined;
      case 'forum':
        return Icons.forum_outlined;
      case 'workshop':
        return Icons.build_outlined;
      default:
        return Icons.school_outlined;
    }
  }

  void _showGradeDetail(BuildContext context, GradeItem item) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    item.itemName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.itemModule != null) ...[
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(item.itemModule!),
                      avatar: Icon(_moduleIcon(item.itemModule!), size: 16),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Grade display
                  Card(
                    color: item.gradeRaw != null
                        ? _gradeColor(
                            item.percentageFormatted,
                          ).withValues(alpha: 0.08)
                        : Colors.grey.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _GradeStatColumn(
                            label: 'grades.grade'.tr(),
                            value: item.gradeRaw?.toStringAsFixed(1) ?? '-',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _GradeStatColumn(
                            label: 'grades.max'.tr(),
                            value: item.gradeMax?.toStringAsFixed(0) ?? '-',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          _GradeStatColumn(
                            label: 'grades.percentage'.tr(),
                            value: item.percentageFormatted != null
                                ? '${item.percentageFormatted!.toStringAsFixed(1)}%'
                                : '-',
                            valueColor: _gradeColor(item.percentageFormatted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dates
                  if (item.gradeDateSubmitted != null ||
                      item.gradeDateGraded != null) ...[
                    Text(
                      'grades.dates'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (item.gradeDateSubmitted != null)
                      _DetailRow(
                        icon: Icons.upload,
                        label: 'grades.date_submitted'.tr(),
                        value: item.gradeDateSubmitted!,
                      ),
                    if (item.gradeDateGraded != null)
                      _DetailRow(
                        icon: Icons.grading,
                        label: 'grades.graded_on'.tr(),
                        value: item.gradeDateGraded!,
                      ),
                    const SizedBox(height: 16),
                  ],
                  // Feedback
                  if (item.feedback != null && item.feedback!.isNotEmpty) ...[
                    Text(
                      'grades.feedback'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: HtmlWidget(
                          item.feedback!,
                          textStyle: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GradeStatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _GradeStatColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondaryLight),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
