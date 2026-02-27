import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/grade.dart';
import '../bloc/grades_bloc.dart';

/// Grades overview page. Shows course-level grades with chart,
/// or per-course grade items.
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
                    leftTitles: AxisTitles(
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
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item.itemName),
            subtitle: item.itemModule != null ? Text(item.itemModule!) : null,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.gradeRaw != null
                      ? item.gradeRaw!.toStringAsFixed(1)
                      : '-',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.gradeMax != null)
                  Text(
                    '/ ${item.gradeMax!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
