import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/gamification_entities.dart';
import '../bloc/challenges_bloc.dart';
import '../widgets/gamification_widgets.dart';

class ChallengesPage extends StatelessWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final userId = authState is AuthAuthenticated ? authState.user.id : 0;

    return BlocProvider(
      create: (_) => sl<ChallengesBloc>()..add(LoadChallenges(userId)),
      child: _ChallengesView(userId: userId),
    );
  }
}

class _ChallengesView extends StatelessWidget {
  final int userId;
  const _ChallengesView({required this.userId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('gamification.challenges')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('gamification.active_tab')),
              Tab(text: tr('gamification.completed_tab')),
            ],
          ),
        ),
        body: BlocConsumer<ChallengesBloc, ChallengesState>(
          listener: (context, state) {
            if (state is RewardClaimed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${tr('gamification.reward_claimed')} +${state.pointsAwarded} ${tr('gamification.pts')}!',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ChallengesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ChallengesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 12),
                    Text(state.message),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => context
                          .read<ChallengesBloc>()
                          .add(LoadChallenges(userId)),
                      child: Text(tr('common.retry')),
                    ),
                  ],
                ),
              );
            }

            if (state is ChallengesLoaded) {
              return TabBarView(
                children: [
                  _ChallengesList(
                    challenges: state.active,
                    userId: userId,
                    emptyIcon: Icons.flag_rounded,
                    emptyMessage: tr('gamification.no_active_challenges'),
                  ),
                  _ChallengesList(
                    challenges: state.completed,
                    userId: userId,
                    emptyIcon: Icons.emoji_events_rounded,
                    emptyMessage: tr('gamification.no_completed_challenges'),
                    isCompleted: true,
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

class _ChallengesList extends StatelessWidget {
  final List<Challenge> challenges;
  final int userId;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool isCompleted;

  const _ChallengesList({
    required this.challenges,
    required this.userId,
    required this.emptyIcon,
    required this.emptyMessage,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppColors.textTertiaryLight),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 60),
          child: ChallengeCard(
            challenge: challenge,
            onClaim: challenge.status == ChallengeStatus.completed
                ? () => context.read<ChallengesBloc>().add(
                      ClaimChallengeReward(
                        challengeId: challenge.id,
                        userId: userId,
                      ),
                    )
                : null,
          ),
        );
      },
    );
  }
}
