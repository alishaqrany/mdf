import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/social_entities.dart';

/// A card widget displaying a single study note.
class NoteCard extends StatelessWidget {
  final StudyNote note;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final VoidCallback? onBookmark;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    this.onLike,
    this.onBookmark,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _VisibilityBadge(visibility: note.visibility),
                ],
              ),
              const SizedBox(height: 6),

              // Content preview
              Text(
                note.content,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Tags
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 10),

              // Bottom row — author, date, actions
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    note.authorName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textTertiaryLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMd().format(note.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const Spacer(),

                  // Like
                  InkWell(
                    onTap: onLike,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            note.isLiked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 16,
                            color: note.isLiked
                                ? AppColors.accent
                                : AppColors.textTertiaryLight,
                          ),
                          if (note.likes > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '${note.likes}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: note.isLiked
                                    ? AppColors.accent
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Bookmark
                  InkWell(
                    onTap: onBookmark,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        note.isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 16,
                        color: note.isBookmarked
                            ? AppColors.primary
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Comment count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: AppColors.textTertiaryLight,
                      ),
                      if (note.commentCount > 0) ...[
                        const SizedBox(width: 2),
                        Text(
                          '${note.commentCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisibilityBadge extends StatelessWidget {
  final NoteVisibility visibility;

  const _VisibilityBadge({required this.visibility});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (visibility) {
      NoteVisibility.personal => (Icons.person, AppColors.textTertiaryLight),
      NoteVisibility.group => (Icons.group, AppColors.info),
      NoteVisibility.course => (Icons.school, AppColors.primary),
      NoteVisibility.public => (Icons.public, AppColors.secondary),
    };

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }
}
