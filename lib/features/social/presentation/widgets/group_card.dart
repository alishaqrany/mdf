import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/social_entities.dart';

/// A card widget displaying a single study group.
class GroupCard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback onTap;
  final VoidCallback? onJoin;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Group avatar / icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.secondary.withValues(alpha: 0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: group.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: group.imageUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.groups_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!group.isPublic)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(start: 4),
                            child: Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                      ],
                    ),
                    if (group.description != null &&
                        group.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        group.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                          color: AppColors.textTertiaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberCount}/${group.maxMembers}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (group.courseName != null) ...[
                          const Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              group.courseName!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiaryLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Join button or chevron
              if (group.currentUserRole == null &&
                  onJoin != null &&
                  !group.isFull) ...[
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ] else ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiaryLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
