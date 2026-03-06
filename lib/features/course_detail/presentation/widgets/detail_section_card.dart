import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/colors.dart';
import '../../../course_content/domain/entities/course_content.dart';
import '../../../course_content/presentation/bloc/course_content_bloc.dart';
import 'detail_module_item.dart';
import 'detail_sub_section_expander.dart';

/// Expandable card representing one course section with its modules.
class DetailSectionCard extends StatefulWidget {
  final CourseSection section;
  final int courseId;
  final bool initiallyExpanded;
  final bool editMode;

  const DetailSectionCard({
    super.key,
    required this.section,
    required this.courseId,
    this.initiallyExpanded = false,
    this.editMode = false,
  });

  @override
  State<DetailSectionCard> createState() => _DetailSectionCardState();
}

class _DetailSectionCardState extends State<DetailSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = widget.section.modules
        .where((m) => m.completionState == 1)
        .length;
    final totalModules = widget.section.modules.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _expanded ? AppColors.primarySurface : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.section.sectionNumber}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.name.isNotEmpty
                              ? widget.section.name
                              : tr('content.section_unnamed'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (totalModules > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$completedCount / $totalModules ${tr("content.activities")}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                ...widget.section.modules.map((module) {
                  if (module.isSubSection) {
                    return DetailSubSectionExpander(
                      module: module,
                      courseId: widget.courseId,
                    );
                  }
                  return DetailModuleItem(
                    module: module,
                    courseId: widget.courseId,
                    editMode: widget.editMode,
                  );
                }),
                if (widget.editMode)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final loc = GoRouterState.of(context).matchedLocation;
                        final prefix = loc.startsWith('/admin')
                            ? '/admin'
                            : loc.startsWith('/teacher')
                            ? '/teacher'
                            : '/student';
                        final result = await context.push<bool>(
                          '$prefix/course/${widget.courseId}/add-activity/${widget.section.sectionNumber}?sectionName=${Uri.encodeComponent(widget.section.name)}',
                        );
                        // Reload course content if an activity was added
                        if (result == true && context.mounted) {
                          context.read<CourseContentBloc>().add(
                            LoadCourseContent(courseId: widget.courseId),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(tr('course_mgmt.add_activity')),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ),
              ],
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}
