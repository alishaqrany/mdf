import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/social_entities.dart';

/// A card widget displaying a single peer review.
class ReviewCard extends StatelessWidget {
  final PeerReview review;
  final VoidCallback onTap;

  const ReviewCard({super.key, required this.review, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(review.status);

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
              // Status indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(review.status),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Review info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.workshopName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      review.submitterName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(review.status),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (review.submittedAt != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: AppColors.textTertiaryLight,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            DateFormat.yMd().format(review.submittedAt!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Rating badge (if completed)
              if (review.status == PeerReviewStatus.completed &&
                  review.rating != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        review.rating!.toStringAsFixed(1),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '/${review.maxRating.toInt()}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiaryLight,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
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

  Color _statusColor(PeerReviewStatus status) {
    switch (status) {
      case PeerReviewStatus.pending:
        return AppColors.warning;
      case PeerReviewStatus.inProgress:
        return AppColors.info;
      case PeerReviewStatus.completed:
        return AppColors.success;
      case PeerReviewStatus.overdue:
        return AppColors.error;
    }
  }

  IconData _statusIcon(PeerReviewStatus status) {
    switch (status) {
      case PeerReviewStatus.pending:
        return Icons.pending_actions_rounded;
      case PeerReviewStatus.inProgress:
        return Icons.rate_review_rounded;
      case PeerReviewStatus.completed:
        return Icons.check_circle_rounded;
      case PeerReviewStatus.overdue:
        return Icons.warning_rounded;
    }
  }

  String _statusLabel(PeerReviewStatus status) {
    switch (status) {
      case PeerReviewStatus.pending:
        return 'Pending';
      case PeerReviewStatus.inProgress:
        return 'In Progress';
      case PeerReviewStatus.completed:
        return 'Completed';
      case PeerReviewStatus.overdue:
        return 'Overdue';
    }
  }
}
