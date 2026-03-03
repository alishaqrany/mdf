import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/gamification_entities.dart';
import '../bloc/leaderboard_bloc.dart';
import '../widgets/gamification_widgets.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<LeaderboardBloc>()
            ..add(const LoadLeaderboard(period: LeaderboardPeriod.allTime)),
      child: const _LeaderboardView(),
    );
  }
}

class _LeaderboardView extends StatelessWidget {
  const _LeaderboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('gamification.leaderboard')),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            onTap: (index) {
              const periods = LeaderboardPeriod.values;
              context.read<LeaderboardBloc>().add(ChangePeriod(periods[index]));
            },
            tabs: [
              Tab(text: tr('gamification.period_daily')),
              Tab(text: tr('gamification.period_weekly')),
              Tab(text: tr('gamification.period_monthly')),
              Tab(text: tr('gamification.period_all')),
            ],
          ),
        ),
        body: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            if (state is LeaderboardLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LeaderboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(state.message),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context.read<LeaderboardBloc>().add(
                        const LoadLeaderboard(
                          period: LeaderboardPeriod.allTime,
                        ),
                      ),
                      child: Text(tr('common.retry')),
                    ),
                  ],
                ),
              );
            }

            if (state is LeaderboardLoaded) {
              if (state.entries.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.leaderboard_rounded,
                        size: 64,
                        color: AppColors.textTertiaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr('gamification.no_leaderboard'),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  // Top 3 podium
                  if (state.entries.length >= 3)
                    FadeInDown(
                      duration: const Duration(milliseconds: 500),
                      child: _TopThreePodium(
                        entries: state.entries.take(3).toList(),
                      ),
                    ),

                  // Current user rank (if not in top 3)
                  if (state.currentUser != null && state.currentUser!.rank > 3)
                    FadeInUp(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#${state.currentUser!.rank}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.person_rounded,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr('gamification.your_rank'),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${state.currentUser!.points} ${tr('gamification.pts')}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Full list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: state.entries.length,
                      itemBuilder: (context, index) => FadeInRight(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: index * 40),
                        child: LeaderboardTile(entry: state.entries[index]),
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}

// ─── Top 3 Podium ───
class _TopThreePodium extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const _TopThreePodium({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entries.length > 1) _PodiumItem(entry: entries[1], height: 80),
          const SizedBox(width: 8),
          _PodiumItem(entry: entries[0], height: 100),
          const SizedBox(width: 8),
          if (entries.length > 2) _PodiumItem(entry: entries[2], height: 64),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;

  const _PodiumItem({required this.entry, required this.height});

  Color get _medalColor {
    switch (entry.rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal icon
        Icon(Icons.emoji_events_rounded, color: _medalColor, size: 28),
        const SizedBox(height: 4),
        // Avatar
        CircleAvatar(
          radius: entry.rank == 1 ? 32 : 26,
          backgroundColor: _medalColor.withValues(alpha: 0.2),
          backgroundImage: entry.profileImageUrl != null
              ? CachedNetworkImageProvider(entry.profileImageUrl!)
              : null,
          child: entry.profileImageUrl == null
              ? Text(
                  entry.fullName.isNotEmpty
                      ? entry.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _medalColor,
                    fontSize: entry.rank == 1 ? 20 : 16,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 6),
        // Name
        SizedBox(
          width: 80,
          child: Text(
            entry.fullName,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Points
        Text(
          '${entry.points}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: _medalColor,
          ),
        ),
        const SizedBox(height: 4),
        // Podium block
        Container(
          width: entry.rank == 1 ? 80 : 70,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _medalColor.withValues(alpha: 0.3),
                _medalColor.withValues(alpha: 0.15),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: _medalColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
