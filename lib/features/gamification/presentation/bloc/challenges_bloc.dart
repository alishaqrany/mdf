import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gamification_entities.dart';
import '../../domain/repositories/gamification_repository.dart';

// ─── Events ───

abstract class ChallengesEvent extends Equatable {
  const ChallengesEvent();
  @override
  List<Object?> get props => [];
}

class LoadChallenges extends ChallengesEvent {
  final int userId;
  const LoadChallenges(this.userId);
  @override
  List<Object?> get props => [userId];
}

class ClaimChallengeReward extends ChallengesEvent {
  final int challengeId;
  final int userId;
  const ClaimChallengeReward({
    required this.challengeId,
    required this.userId,
  });
  @override
  List<Object?> get props => [challengeId, userId];
}

// ─── States ───

abstract class ChallengesState extends Equatable {
  const ChallengesState();
  @override
  List<Object?> get props => [];
}

class ChallengesInitial extends ChallengesState {}

class ChallengesLoading extends ChallengesState {}

class ChallengesLoaded extends ChallengesState {
  final List<Challenge> active;
  final List<Challenge> completed;

  const ChallengesLoaded({
    required this.active,
    required this.completed,
  });

  @override
  List<Object?> get props => [active, completed];
}

class RewardClaimed extends ChallengesState {
  final int pointsAwarded;
  const RewardClaimed(this.pointsAwarded);
  @override
  List<Object?> get props => [pointsAwarded];
}

class ChallengesError extends ChallengesState {
  final String message;
  const ChallengesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───

class ChallengesBloc extends Bloc<ChallengesEvent, ChallengesState> {
  final GamificationRepository repository;

  ChallengesBloc({required this.repository}) : super(ChallengesInitial()) {
    on<LoadChallenges>(_onLoad);
    on<ClaimChallengeReward>(_onClaim);
  }

  Future<void> _onLoad(
    LoadChallenges event,
    Emitter<ChallengesState> emit,
  ) async {
    emit(ChallengesLoading());
    final activeResult = await repository.getActiveChallenges(event.userId);
    final completedResult =
        await repository.getCompletedChallenges(event.userId);

    activeResult.fold(
      (failure) => emit(ChallengesError(failure.message)),
      (active) {
        completedResult.fold(
          (failure) => emit(ChallengesError(failure.message)),
          (completed) =>
              emit(ChallengesLoaded(active: active, completed: completed)),
        );
      },
    );
  }

  Future<void> _onClaim(
    ClaimChallengeReward event,
    Emitter<ChallengesState> emit,
  ) async {
    final result =
        await repository.claimChallengeReward(event.challengeId, event.userId);
    result.fold(
      (failure) => emit(ChallengesError(failure.message)),
      (challenge) {
        emit(RewardClaimed(challenge.rewardPoints));
        // Reload challenges after claiming
        add(LoadChallenges(event.userId));
      },
    );
  }
}
