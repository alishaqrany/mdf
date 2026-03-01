import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';

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
          create: (_) =>
              sl<PointsBloc>()..add(LoadPointHistory(userId)),
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
      child: _GamificationDashboardView(userId: userId),
    );
  }
}

class _GamificationDashboardView extends StatelessWidget {
  final int userId;
  const _GamificationDashboardView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('gamification.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: tr('gamification.history'),
            onPressed: () {
              _showPointHistory(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<PointsBloc>().add(LoadPointHistory(userId));
          context.read<BadgesBloc>().add(LoadAllBadges(userId));
          context.read<ChallengesBloc>().add(LoadChallenges(userId));
          context
              .read<LeaderboardBloc>()
              .add(const LoadLeaderboard(limit: 5));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Points Banner ───
              BlocBuilder<PointsBloc, PointsState>(
                builder: (context, state) {
                  if (state is PointsLoaded) {
                    return PointsBanner(userPoints: state.userPoints);
                  }
                  if (state is PointsLoading) {
                    return const _BannerShimmer();
                  }
                  return const SizedBox();
                },
              ),

              // ─── Streak ───
              BlocBuilder<PointsBloc, PointsState>(
                builder: (context, state) {
                  if (state is PointsLoaded) {
                    return FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 100),
                      child: StreakWidget(
                        currentStreak: state.userPoints.currentStreak,
                        longestStreak: state.userPoints.longestStreak,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),

              // ─── Active Challenges Section ───
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 200),
                child: _SectionHeader(
                  title: tr('gamification.active_challenges'),
                  actionLabel: tr('gamification.view_all'),
                  onAction: () => context.push('/student/challenges'),
                ),
              ),
              BlocBuilder<ChallengesBloc, ChallengesState>(
                builder: (context, state) {
                  if (state is ChallengesLoaded) {
                    if (state.active.isEmpty) {
                      return _EmptySection(
                        icon: Icons.flag_rounded,
                        message: tr('gamification.no_challenges'),
                      );
                    }
                    return Column(
                      children: state.active.take(3).map((c) {
                        return FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: ChallengeCard(
                            challenge: c,
                            onClaim: c.status == ChallengeStatus.completed
                                ? () => context
                                    .read<ChallengesBloc>()
                                    .add(ClaimChallengeReward(
                                      challengeId: c.id,
                                      userId: userId,
                                    ))
                                : null,
                          ),
                        );
                      }).toList(),
                    );
                  }
                  if (state is ChallengesLoading) {
                    return const _ListShimmer(count: 2);
                  }
                  return const SizedBox();
                },
              ),

              // ─── Badges Preview ───
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 300),
                child: _SectionHeader(
                  title: tr('gamification.badges'),
                  actionLabel: tr('gamification.view_all'),
                  onAction: () => context.push('/student/badges'),
                ),
              ),
              BlocBuilder<BadgesBloc, BadgesState>(
                builder: (context, state) {
                  if (state is BadgesLoaded) {
                    if (state.allBadges.isEmpty) {
                      return _EmptySection(
                        icon: Icons.military_tech_rounded,
                        message: tr('gamification.no_badges'),
                      );
                    }
                    // Show up to 4 recent/earned badges
                    final preview = [
                      ...state.earned.take(4),
                      if (state.earned.length < 4)
                        ...state.locked.take(4 - state.earned.length),
                    ];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: preview.length,
                        itemBuilder: (context, index) => FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          delay: Duration(milliseconds: index * 80),
                          child: BadgeCard(badge: preview[index]),
                        ),
                      ),
                    );
                  }
                  if (state is BadgesLoading) {
                    return const _GridShimmer();
                  }
                  return const SizedBox();
                },
              ),

              // ─── Leaderboard Preview ───
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 400),
                child: _SectionHeader(
                  title: tr('gamification.leaderboard'),
                  actionLabel: tr('gamification.view_all'),
                  onAction: () => context.push('/student/leaderboard'),
                ),
              ),
              BlocBuilder<LeaderboardBloc, LeaderboardState>(
                builder: (context, state) {
                  if (state is LeaderboardLoaded) {
                    if (state.entries.isEmpty) {
                      return _EmptySection(
                        icon: Icons.leaderboard_rounded,
                        message: tr('gamification.no_leaderboard'),
                      );
                    }
                    return Column(
                      children: state.entries.take(5).map((e) {
                        return FadeInRight(
                          duration: const Duration(milliseconds: 300),
                          child: LeaderboardTile(entry: e),
                        );
                      }).toList(),
                    );
                  }
                  if (state is LeaderboardLoading) {
                    return const _ListShimmer(count: 3);
                  }
                  return const SizedBox();
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  void _showPointHistory(BuildContext context) {
    final state = context.read<PointsBloc>().state;
    if (state is! PointsLoaded || state.history.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          final theme = Theme.of(context);
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
                child: Text(
                  tr('gamification.history'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.history.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final tx = state.history[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tx.points > 0
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.error.withValues(alpha: 0.12),
                        child: Icon(
                          tx.points > 0
                              ? Icons.add_rounded
                              : Icons.remove_rounded,
                          color: tx.points > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                      title: Text(tx.description),
                      subtitle: Text(
                        DateFormat('yyyy/MM/dd HH:mm').format(tx.createdAt),
                        style: theme.textTheme.bodySmall,
                      ),
                      trailing: Text(
                        '${tx.points > 0 ? '+' : ''}${tx.points}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: tx.points > 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Section Header ───
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Empty Section ───
class _EmptySection extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptySection({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiaryLight),
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

// ─── Shimmers ───
class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

class _ListShimmer extends StatelessWidget {
  final int count;
  const _ListShimmer({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (_) => Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.shimmerBase.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: AppColors.shimmerBase.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
