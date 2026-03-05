import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/colors.dart';
import '../../../course_content/domain/entities/course_content.dart';
import '../../../course_content/presentation/bloc/course_content_bloc.dart';
import 'detail_module_item.dart';

/// Expandable widget for subsections inside a course section.
class DetailSubSectionExpander extends StatefulWidget {
  final CourseModule module;
  final int courseId;

  const DetailSubSectionExpander({
    super.key,
    required this.module,
    required this.courseId,
  });

  @override
  State<DetailSubSectionExpander> createState() =>
      _DetailSubSectionExpanderState();
}

class _DetailSubSectionExpanderState extends State<DetailSubSectionExpander> {
  bool _expanded = false;

  CourseSection? _findLinkedSection() {
    final state = context.read<CourseContentBloc>().state;
    if (state is! CourseContentLoaded) return null;

    CourseSection? parentSection;
    for (final s in state.sections) {
      if (s.modules.any((m) => m.id == widget.module.id)) {
        parentSection = s;
        break;
      }
    }

    for (final s in state.sections) {
      if (identical(s, parentSection)) continue;
      if (s.name == widget.module.name) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkedSection = _findLinkedSection();
    final modules = linkedSection?.modules ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.folder_special_rounded,
                    color: AppColors.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.module.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (modules.isNotEmpty)
                        Text(
                          '${modules.length} ${tr("content.activities")}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Container(
            margin: const EdgeInsets.only(left: 24),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.info.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: modules
                  .map(
                    (m) =>
                        DetailModuleItem(module: m, courseId: widget.courseId),
                  )
                  .toList(),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }
}
