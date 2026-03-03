import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/gamification_entities.dart';
import '../bloc/points_bloc.dart';
import '../bloc/badges_bloc.dart';
import '../bloc/challenges_bloc.dart';
import '../bloc/leaderboard_bloc.dart';
import '../widgets/gamification_widgets.dart';

class GamificationDashboardPage extends StatelessWidget {
  const GamificationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PointsBloc>()..add(LoadPointHistory(userId)),
        ),
        BlocProvider(
          create: (_) => sl<BadgesBloc>()..add(LoadAllBadges(userId)),
        ),
        BlocProvider(
          create: (_) => sl<ChallengesBloc>()..add(LoadChallenges(userId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<LeaderboardBloc>()..add(const LoadLeaderboard(limit: 5)),
        ),
      ],
      child: _DashboardView(userId: userId),
    );
  }
}

class _DashboardView extends StatelessWidget {
  final int userId;
  const _DashboardView({required this.userId});

  void _refresh(BuildContext context) {
    context.read<PointsBloc>().add(LoadPointHistory(userId));
    context.read<BadgesBloc>().add(LoadAllBadges(userId));
    context.read<ChallengesBloc>().add(LoadChallenges(userId));
    context.read<LeaderboardBloc>().add(const LoadLeaderboard(limit: 5));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PointsBloc, PointsState>(
        builder: (context, pointsState) {
          // ── Error state (plugin not installed) ──
          if (pointsState is PointsError) {
            return _FullScreenError(
              message: pointsState.message,
              onRetry: () => _refresh(context),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _refresh(context),
            edgeOffset: 120,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── Hero AppBar ──
                _buildHeroAppBar(context, pointsState),

                // ── Quick Stats ──
                if (pointsState is PointsLoaded)
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: _QuickStats(userPoints: pointsState.userPoints),
                    ),
                  ),

                // ── Loading shimmer ──
                if (pointsState is PointsLoading)
                  const SliverToBoxAdapter(child: _DashboardShimmer()),

                // ── Challenges Section ──
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 100),
                    child: _ChallengesSection(userId: userId),
                  ),
                ),

                // ── Badges Section ──
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 200),
                    child: _BadgesSection(userId: userId),
                  ),
                ),

                // ── Leaderboard Section ──
                SliverToBoxAdapter(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: const Duration(milliseconds: 300),
                    child: _LeaderboardSection(userId: userId),
                  ),
                ),

                // ── Recent Activity ──
                if (pointsState is PointsLoaded &&
                    pointsState.history.isNotEmpty)
                  SliverToBoxAdapter(
                    child: FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 400),
                      child: _RecentActivity(history: pointsState.history),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroAppBar(BuildContext context, PointsState pointsState) {
    return SliverAppBar(
      expandedHeight: pointsState is PointsLoaded ? 280 : 160,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF4A42E8), Color(0xFF3730A3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: pointsState is PointsLoaded
                ? _HeroProfile(userPoints: pointsState.userPoints)
                : const SizedBox.shrink(),
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 16),
        title: Text(
          tr('gamification.title'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
        ),
      ),
      actions: [
        if (pointsState is PointsLoaded && pointsState.history.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.timeline_rounded, color: Colors.white),
            tooltip: tr('gamification.history'),
            onPressed: () => _showPointHistory(context, pointsState),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showPointHistory(BuildContext context, PointsLoaded state) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.timeline_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        tr('gamification.history'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final tx = state.history[index];
                      return _TransactionTile(
                        tx: tx,
                        isPositive: tx.points > 0,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Hero Profile (inside SliverAppBar)
// ═══════════════════════════════════════════════

class _HeroProfile extends StatelessWidget {
  final UserPoints userPoints;
  const _HeroProfile({required this.userPoints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // ─ Circle progress with level ─
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: CircularPercentIndicator(
              radius: 52,
              lineWidth: 6,
              percent: userPoints.levelProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              progressColor: Colors.amber,
              circularStrokeCap: CircularStrokeCap.round,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${userPoints.level}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Text(
                    tr('gamification.level'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // ─ Level title ─
          FadeIn(
            duration: const Duration(milliseconds: 600),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                userPoints.levelTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.amber.shade200,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ─ XP Progress bar ─
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${userPoints.currentLevelPoints}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${userPoints.nextLevelPoints} XP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 200,
                  child: LinearPercentIndicator(
                    lineHeight: 5,
                    percent: userPoints.levelProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    progressColor: Colors.amber,
                    barRadius: const Radius.circular(3),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Quick Stats Row
// ═══════════════════════════════════════════════

class _QuickStats extends StatelessWidget {
  final UserPoints userPoints;
  const _QuickStats({required this.userPoints});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: _StatMini(
              icon: Icons.stars_rounded,
              iconColor: Colors.amber,
              value: '${userPoints.totalPoints}',
              label: tr('gamification.points'),
              delay: 0,
            ),
          ),
          Expanded(
            child: _StatMini(
              icon: Icons.local_fire_department_rounded,
              iconColor: Colors.deepOrange,
              value: '${userPoints.currentStreak}',
              label: tr('gamification.day_streak'),
              delay: 60,
            ),
          ),
          Expanded(
            child: _StatMini(
              icon: Icons.emoji_events_rounded,
              iconColor: Colors.amber.shade700,
              value: userPoints.rank > 0 ? '#${userPoints.rank}' : '—',
              label: tr('gamification.your_rank'),
              delay: 120,
            ),
          ),
          Expanded(
            child: _StatMini(
              icon: Icons.military_tech_rounded,
              iconColor: AppColors.primary,
              value: '${userPoints.longestStreak}',
              label: tr('gamification.longest'),
              delay: 180,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final int delay;

  const _StatMini({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeInUp(
      duration: const Duration(milliseconds: 350),
      delay: Duration(milliseconds: delay),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Challenges Section
// ═══════════════════════════════════════════════

class _ChallengesSection extends StatelessWidget {
  final int userId;
  const _ChallengesSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChallengesBloc, ChallengesState>(
      builder: (context, state) {
        if (state is ChallengesLoading) {
          return _SectionCard(
            title: tr('gamification.active_challenges'),
            child: const _CardShimmer(height: 80),
          );
        }
        if (state is ChallengesLoaded) {
          return _SectionCard(
            title: tr('gamification.active_challenges'),
            actionLabel: tr('gamification.view_all'),
            onAction: () => context.push('/student/challenges'),
            child: state.active.isEmpty
                ? _EmptyHint(
                    icon: Icons.flag_rounded,
                    message: tr('gamification.no_challenges'),
                  )
                : Column(
                    children: state.active.take(3).map((c) {
                      return ChallengeCard(
                        challenge: c,
                        onClaim: c.status == ChallengeStatus.completed
                            ? () => context.read<ChallengesBloc>().add(
                                ClaimChallengeReward(
                                  challengeId: c.id,
                                  userId: userId,
                                ),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Badges Section (horizontal scroll preview)
// ═══════════════════════════════════════════════

class _BadgesSection extends StatelessWidget {
  final int userId;
  const _BadgesSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgesBloc, BadgesState>(
      builder: (context, state) {
        if (state is BadgesLoading) {
          return _SectionCard(
            title: tr('gamification.badges'),
            child: const _CardShimmer(height: 100),
          );
        }
        if (state is BadgesLoaded) {
          final preview = [
            ...state.earned.take(6),
            if (state.earned.length < 6)
              ...state.locked.take(6 - state.earned.length),
          ];
          return _SectionCard(
            title: tr('gamification.badges'),
            actionLabel: tr('gamification.view_all'),
            onAction: () => context.push('/student/badges'),
            child: preview.isEmpty
                ? _EmptyHint(
                    icon: Icons.military_tech_rounded,
                    message: tr('gamification.no_badges'),
                  )
                : SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: preview.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => FadeInRight(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: index * 60),
                        child: SizedBox(
                          width: 82,
                          child: BadgeCard(badge: preview[index]),
                        ),
                      ),
                    ),
                  ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Leaderboard Section (compact preview)
// ═══════════════════════════════════════════════

class _LeaderboardSection extends StatelessWidget {
  final int userId;
  const _LeaderboardSection({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeaderboardBloc, LeaderboardState>(
      builder: (context, state) {
        if (state is LeaderboardLoading) {
          return _SectionCard(
            title: tr('gamification.leaderboard'),
            child: const _CardShimmer(height: 60),
          );
        }
        if (state is LeaderboardLoaded) {
          return _SectionCard(
            title: tr('gamification.leaderboard'),
            actionLabel: tr('gamification.view_all'),
            onAction: () => context.push('/student/leaderboard'),
            child: state.entries.isEmpty
                ? _EmptyHint(
                    icon: Icons.leaderboard_rounded,
                    message: tr('gamification.no_leaderboard'),
                  )
                : Column(
                    children: state.entries.take(3).map((e) {
                      return LeaderboardTile(entry: e);
                    }).toList(),
                  ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ═══════════════════════════════════════════════
//  Recent Activity Section
// ═══════════════════════════════════════════════

class _RecentActivity extends StatelessWidget {
  final List<PointTransaction> history;
  const _RecentActivity({required this.history});

  @override
  Widget build(BuildContext context) {
    final recent = history.take(5).toList();

    return _SectionCard(
      title: tr('gamification.recent_activity'),
      child: Column(
        children: recent.map((tx) {
          return _TransactionTile(tx: tx, isPositive: tx.points > 0);
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Shared UI Components
// ═══════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: AppColors.textTertiaryLight),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final PointTransaction tx;
  final bool isPositive;
  const _TransactionTile({required this.tx, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.success : AppColors.error)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPositive ? Icons.add_rounded : Icons.remove_rounded,
              size: 18,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  DateFormat('MM/dd HH:mm').format(tx.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiaryLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${tx.points}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Full Screen Error
// ═══════════════════════════════════════════════

class _FullScreenError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _FullScreenError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPluginError = message.contains('MDF') || message.contains('mdf');

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Icon(
              isPluginError
                  ? Icons.extension_off_rounded
                  : Icons.error_outline_rounded,
              size: 72,
              color: isPluginError ? AppColors.warning : AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              isPluginError
                  ? tr('gamification.plugin_required')
                  : tr('gamification.error_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isPluginError ? AppColors.warning : AppColors.error)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(tr('common.retry')),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Shimmer Placeholders
// ═══════════════════════════════════════════════

class _DashboardShimmer extends StatelessWidget {
  const _DashboardShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Quick stats shimmer
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Container(
                  height: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Section shimmer
          ...List.generate(
            3,
            (_) => Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.shimmerBase.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShimmer extends StatelessWidget {
  final double height;
  const _CardShimmer({this.height = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
