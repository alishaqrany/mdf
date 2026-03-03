import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../app/theme/colors.dart';
import '../../domain/entities/gamification_entities.dart';

// ═══════════════════════════════════════════════
//  Points Banner (standalone, used externally)
// ═══════════════════════════════════════════════

class PointsBanner extends StatelessWidget {
  final UserPoints userPoints;
  final VoidCallback? onTap;

  const PointsBanner({super.key, required this.userPoints, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF4A42E8), Color(0xFF3730A3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Level circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${userPoints.level}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rank
                if (userPoints.rank > 0)
                  Column(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                      Text(
                        '#${userPoints.rank}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // XP Progress
            LinearPercentIndicator(
              lineHeight: 6,
              percent: userPoints.levelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              progressColor: Colors.amber,
              barRadius: const Radius.circular(3),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 4),
            Text(
              '${userPoints.currentLevelPoints} / ${userPoints.nextLevelPoints} XP',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Streak Widget
// ═══════════════════════════════════════════════

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Fire icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('🔥', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentStreak ${tr('gamification.day_streak')}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${tr('gamification.longest')}: $longestStreak ${tr('gamification.days')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // Week dots
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(7, (i) {
              final isActive =
                  i < (currentStreak % 7 == 0 ? 7 : currentStreak % 7);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 7,
                  height: isActive ? 22 : 10,
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.amber
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3.5),
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

// ═══════════════════════════════════════════════
//  Badge Card
// ═══════════════════════════════════════════════

class BadgeCard extends StatelessWidget {
  final Badge badge;
  final VoidCallback? onTap;

  const BadgeCard({super.key, required this.badge, this.onTap});

  Color get _rarityColor {
    switch (badge.rarity) {
      case BadgeRarity.common:
        return Colors.grey.shade500;
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
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: badge.isEarned
              ? _rarityColor.withValues(alpha: isDark ? 0.12 : 0.06)
              : isDark
                  ? Colors.grey.withValues(alpha: 0.08)
                  : Colors.grey.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isEarned
                ? _rarityColor.withValues(alpha: 0.35)
                : Colors.grey.withValues(alpha: isDark ? 0.15 : 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: badge.isEarned
                      ? _rarityColor.withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _badgeIcon,
                  size: 22,
                  color: badge.isEarned ? _rarityColor : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 6),
              // Name
              Text(
                badge.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: badge.isEarned ? null : AppColors.textTertiaryLight,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              // Rarity chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _rarityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge.rarity.name.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _rarityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 7,
                  ),
                ),
              ),
              // Progress for locked badges
              if (!badge.isEarned && badge.earnedPercentage > 0) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 50,
                  child: LinearPercentIndicator(
                    lineHeight: 3,
                    percent: (badge.earnedPercentage / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.withValues(alpha: 0.12),
                    progressColor: _rarityColor,
                    barRadius: const Radius.circular(1.5),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Leaderboard Tile
// ═══════════════════════════════════════════════

class LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardTile({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTop3 = entry.rank <= 3;
    final isCurrentUser = entry.isCurrentUser;

    Color? rankColor;
    if (entry.rank == 1) rankColor = Colors.amber;
    if (entry.rank == 2) rankColor = Colors.grey.shade400;
    if (entry.rank == 3) rankColor = Colors.brown.shade300;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06)
            : isTop3
                ? rankColor?.withValues(alpha: isDark ? 0.1 : 0.04)
                : null,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 30,
            child: isTop3
                ? Icon(
                    Icons.emoji_events_rounded,
                    color: rankColor,
                    size: 22,
                  )
                : Text(
                    '#${entry.rank}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primarySurface,
            backgroundImage: entry.profileImageUrl != null
                ? CachedNetworkImageProvider(entry.profileImageUrl!)
                : null,
            child: entry.profileImageUrl == null
                ? Text(
                    entry.fullName.isNotEmpty
                        ? entry.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Name + Level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiaryLight,
                        fontSize: 10,
                      ),
                    ),
                    if (entry.currentStreak > 0) ...[
                      const SizedBox(width: 6),
                      const Text('🔥', style: TextStyle(fontSize: 10)),
                      Text(
                        '${entry.currentStreak}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Points
          Text(
            '${entry.points}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            tr('gamification.pts'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiaryLight,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Challenge Card
// ═══════════════════════════════════════════════

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
    final isDark = theme.brightness == Brightness.dark;
    final canClaim =
        challenge.status == ChallengeStatus.completed && onClaim != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: canClaim
            ? AppColors.success.withValues(alpha: isDark ? 0.12 : 0.05)
            : isDark
                ? AppColors.surfaceDark
                : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canClaim
              ? AppColors.success.withValues(alpha: 0.35)
              : isDark
                  ? AppColors.dividerDark
                  : AppColors.divider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _periodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon, color: _periodColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Period badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: _periodColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
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
          const SizedBox(height: 10),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearPercentIndicator(
                  lineHeight: 6,
                  percent: challenge.progress.clamp(0.0, 1.0),
                  backgroundColor: isDark
                      ? AppColors.dividerDark
                      : AppColors.divider,
                  progressColor: canClaim ? AppColors.success : _periodColor,
                  barRadius: const Radius.circular(3),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${challenge.currentValue}/${challenge.targetValue}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Reward + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.stars_rounded, size: 15, color: Colors.amber.shade600),
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
              if (canClaim)
                SizedBox(
                  height: 30,
                  child: FilledButton.icon(
                    onPressed: onClaim,
                    icon: const Icon(Icons.redeem_rounded, size: 14),
                    label: Text(
                      tr('gamification.claim'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else if (!challenge.isExpired)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 13, color: AppColors.textTertiaryLight),
                    const SizedBox(width: 3),
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
