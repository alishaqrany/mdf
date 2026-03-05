import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../app/theme/colors.dart';
import '../../../courses/domain/entities/course.dart';

/// Card showing course title, summary, progress bar, meta chips, and instructors.
class CourseInfoCard extends StatelessWidget {
  final Course course;
  const CourseInfoCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = course.progress ?? 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.fullName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (course.summary != null && course.summary!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _stripHtml(course.summary!),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearPercentIndicator(
                    lineHeight: 8,
                    percent: (progress / 100).clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    progressColor: AppColors.primary,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${progress.toInt()}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (course.categoryName != null)
                  _InfoChip(icon: Icons.category, label: course.categoryName!),
                if (course.shortName.isNotEmpty)
                  _InfoChip(icon: Icons.code, label: course.shortName),
                if (course.enrolledUserCount != null)
                  _InfoChip(
                    icon: Icons.people,
                    label:
                        '${course.enrolledUserCount} ${tr("courses.students")}',
                  ),
              ],
            ),
            if (course.contacts.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr('courses.instructor'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...course.contacts.map(
                (contact) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: contact.profileImageUrl != null
                            ? CachedNetworkImageProvider(
                                contact.profileImageUrl!,
                              )
                            : null,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.1,
                        ),
                        child: contact.profileImageUrl == null
                            ? Text(
                                contact.fullName.isNotEmpty
                                    ? contact.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contact.fullName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
