import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/gamification_entities.dart';

// ─── Points Banner ───
class PointsBanner extends StatelessWidget {
  final UserPoints userPoints;
  final VoidCallback? onTap;

  const PointsBanner({super.key, required this.userPoints, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B83FF), Color(0xFFAB47BC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Row(
                children: [
                  // Level badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${userPoints.level}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userPoints.levelTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${userPoints.totalPoints} ${tr('gamification.points')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Rank
                  Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${userPoints.rank}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Level progress bar
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tr('gamification.level')} ${userPoints.level}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        '${tr('gamification.level')} ${userPoints.level + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearPercentIndicator(
                    lineHeight: 8,
                    percent: userPoints.levelProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    progressColor: Colors.amber,
                    barRadius: const Radius.circular(4),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userPoints.currentLevelPoints} / ${userPoints.nextLevelPoints} XP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                    ),
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

// ─── Streak Widget ───
class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Fire icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak ${tr('gamification.day_streak')}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tr('gamification.longest')}: $longestStreak ${tr('gamification.days')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Streak days visualization
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) {
              final isActive = i < (currentStreak % 7 == 0 ? 7 : currentStreak % 7);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 8,
                  height: isActive ? 24 : 12,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.amber
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Badge Card ───
class BadgeCard extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onTap;

  const BadgeCard({super.key, required this.badge, this.onTap});

  Color get _rarityColor {
    switch (badge.rarity) {
      case BadgeRarity.common:
        return Colors.grey;
      case BadgeRarity.uncommon:
        return Colors.green;
      case BadgeRarity.rare:
        return Colors.blue;
      case BadgeRarity.epic:
        return Colors.purple;
      case BadgeRarity.legendary:
        return Colors.amber;
    }
  }

  IconData get _badgeIcon {
    switch (badge.category) {
      case BadgeCategory.general:
        return Icons.star_rounded;
      case BadgeCategory.courses:
        return Icons.school_rounded;
      case BadgeCategory.quizzes:
        return Icons.quiz_rounded;
      case BadgeCategory.assignments:
        return Icons.assignment_turned_in_rounded;
      case BadgeCategory.social:
        return Icons.people_rounded;
      case BadgeCategory.streaks:
        return Icons.local_fire_department_rounded;
      case BadgeCategory.special:
        return Icons.diamond_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: badge.isEarned
              ? _rarityColor.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: badge.isEarned
                ? _rarityColor.withValues(alpha: 0.3)
                : Colors.grey.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: badge.isEarned
                      ? _rarityColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _badgeIcon,
                  size: 28,
                  color: badge.isEarned ? _rarityColor : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                badge.name,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: badge.isEarned
                      ? null
                      : AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Rarity label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _rarityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge.rarity.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _rarityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
              if (!badge.isEarned && badge.earnedPercentage > 0) ...[
                const SizedBox(height: 6),
                LinearPercentIndicator(
                  lineHeight: 4,
                  percent: (badge.earnedPercentage / 100).clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.withValues(alpha: 0.15),
                  progressColor: _rarityColor,
                  barRadius: const Radius.circular(2),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Leaderboard Tile ───
class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTop3 = entry.rank <= 3;
    final isCurrentUser = entry.isCurrentUser;

    Color? rankColor;
    if (entry.rank == 1) rankColor = Colors.amber;
    if (entry.rank == 2) rankColor = Colors.grey.shade400;
    if (entry.rank == 3) rankColor = Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.08)
            : isTop3
                ? rankColor?.withValues(alpha: 0.06)
                : null,
        borderRadius: BorderRadius.circular(14),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 36,
            child: isTop3
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: rankColor,
                    size: 26,
                  )
                : Text(
                    '#${entry.rank}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 10),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: entry.profileImageUrl != null
                ? NetworkImage(entry.profileImageUrl!)
                : null,
            child: entry.profileImageUrl == null
                ? Text(
                    entry.fullName.isNotEmpty
                        ? entry.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight:
                        isCurrentUser ? FontWeight.bold : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Text(
                      '${tr('gamification.level')} ${entry.level}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                    if (entry.currentStreak > 0) ...[
                      const SizedBox(width: 8),
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      Text(
                        '${entry.currentStreak}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.points}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                tr('gamification.pts'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Challenge Card ───
class ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback? onClaim;

  const ChallengeCard({super.key, required this.challenge, this.onClaim});

  IconData get _typeIcon {
    switch (challenge.type) {
      case ChallengeType.moduleComplete:
        return Icons.check_circle_outline_rounded;
      case ChallengeType.quizScore:
        return Icons.quiz_rounded;
      case ChallengeType.forumPost:
        return Icons.forum_rounded;
      case ChallengeType.noteCreate:
        return Icons.note_add_rounded;
      case ChallengeType.courseEnroll:
        return Icons.school_rounded;
      case ChallengeType.loginStreak:
        return Icons.local_fire_department_rounded;
      case ChallengeType.studyTime:
        return Icons.schedule_rounded;
    }
  }

  Color get _periodColor {
    return challenge.period == ChallengePeriod.daily
        ? AppColors.secondary
        : AppColors.info;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canClaim =
        challenge.status == ChallengeStatus.completed && onClaim != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: canClaim
            ? AppColors.success.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: canClaim
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Type icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _periodColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon, color: _periodColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Period badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _periodColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            challenge.period == ChallengePeriod.daily
                                ? tr('gamification.daily')
                                : tr('gamification.weekly'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _periodColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      challenge.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearPercentIndicator(
                  lineHeight: 8,
                  percent: challenge.progress.clamp(0.0, 1.0),
                  backgroundColor: AppColors.divider,
                  progressColor:
                      canClaim ? AppColors.success : _periodColor,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${challenge.currentValue}/${challenge.targetValue}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reward and action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reward
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${challenge.rewardPoints} ${tr('gamification.pts')}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Time remaining or claim button
              if (canClaim)
                ElevatedButton.icon(
                  onPressed: onClaim,
                  icon: const Icon(Icons.redeem_rounded, size: 16),
                  label: Text(tr('gamification.claim')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    textStyle: const TextStyle(fontSize: 12),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                )
              else if (!challenge.isExpired)
                Text(
                  _formatRemaining(challenge.remainingTime),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRemaining(Duration d) {
    if (d.inHours >= 24) return '${d.inDays}d';
    if (d.inMinutes >= 60) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }
}
