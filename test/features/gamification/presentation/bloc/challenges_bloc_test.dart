import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/gamification/domain/entities/gamification_entities.dart';
import 'package:mdf_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:mdf_app/features/gamification/presentation/bloc/challenges_bloc.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepository;
  late ChallengesBloc bloc;

  final tActiveChallenge = Challenge(
    id: 1,
    title: 'Complete 3 modules',
    description: 'Complete 3 course modules today',
    type: ChallengeType.moduleComplete,
    period: ChallengePeriod.daily,
    targetValue: 3,
    currentValue: 1,
    rewardPoints: 50,
    startDate: DateTime(2024, 3, 15),
    endDate: DateTime(2024, 3, 16),
    status: ChallengeStatus.active,
  );

  final tCompletedChallenge = Challenge(
    id: 2,
    title: 'Quiz streak',
    description: 'Score 80%+ on 5 quizzes this week',
    type: ChallengeType.quizScore,
    period: ChallengePeriod.weekly,
    targetValue: 5,
    currentValue: 5,
    rewardPoints: 200,
    startDate: DateTime(2024, 3, 11),
    endDate: DateTime(2024, 3, 18),
    status: ChallengeStatus.completed,
  );

  setUp(() {
    mockRepository = MockGamificationRepository();
    bloc = ChallengesBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is ChallengesInitial', () {
    expect(bloc.state, isA<ChallengesInitial>());
  });

  group('LoadChallenges', () {
    blocTest<ChallengesBloc, ChallengesState>(
      'emits [Loading, Loaded] with active and completed challenges',
      build: () {
        when(
          () => mockRepository.getActiveChallenges(1),
        ).thenAnswer((_) async => Right([tActiveChallenge]));
        when(
          () => mockRepository.getCompletedChallenges(1),
        ).thenAnswer((_) async => Right([tCompletedChallenge]));
        return bloc;
      },
      act: (b) => b.add(const LoadChallenges(1)),
      expect: () => [
        isA<ChallengesLoading>(),
        isA<ChallengesLoaded>()
            .having((s) => s.active.length, 'active', 1)
            .having((s) => s.completed.length, 'completed', 1),
      ],
    );

    blocTest<ChallengesBloc, ChallengesState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getActiveChallenges(1),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed')));
        when(
          () => mockRepository.getCompletedChallenges(1),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (b) => b.add(const LoadChallenges(1)),
      expect: () => [isA<ChallengesLoading>(), isA<ChallengesError>()],
    );
  });

  group('ClaimChallengeReward', () {
    final tClaimedChallenge = Challenge(
      id: 2,
      title: 'Quiz streak',
      description: 'Score 80%+ on 5 quizzes this week',
      type: ChallengeType.quizScore,
      period: ChallengePeriod.weekly,
      targetValue: 5,
      currentValue: 5,
      rewardPoints: 200,
      startDate: DateTime(2024, 3, 11),
      endDate: DateTime(2024, 3, 18),
      status: ChallengeStatus.claimed,
    );

    blocTest<ChallengesBloc, ChallengesState>(
      'emits [RewardClaimed] then reloads challenges on success',
      build: () {
        when(
          () => mockRepository.claimChallengeReward(2, 1),
        ).thenAnswer((_) async => Right(tClaimedChallenge));
        // Mock for the re-added LoadChallenges event
        when(
          () => mockRepository.getActiveChallenges(1),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => mockRepository.getCompletedChallenges(1),
        ).thenAnswer((_) async => Right([tClaimedChallenge]));
        return bloc;
      },
      act: (b) => b.add(const ClaimChallengeReward(challengeId: 2, userId: 1)),
      expect: () => [
        isA<RewardClaimed>(),
        // LoadChallenges is re-added, so Loading and Loaded follow
        isA<ChallengesLoading>(),
        isA<ChallengesLoaded>(),
      ],
    );

    blocTest<ChallengesBloc, ChallengesState>(
      'emits [Error] on claim failure',
      build: () {
        when(() => mockRepository.claimChallengeReward(2, 1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Claim failed')),
        );
        return bloc;
      },
      act: (b) => b.add(const ClaimChallengeReward(challengeId: 2, userId: 1)),
      expect: () => [isA<ChallengesError>()],
    );
  });

  group('Challenge entity', () {
    test('progress returns correct fraction', () {
      expect(tActiveChallenge.progress, closeTo(0.333, 0.01));
    });

    test('isCompleted returns correct value', () {
      expect(tActiveChallenge.isCompleted, isFalse);
      expect(tCompletedChallenge.isCompleted, isTrue);
    });

    test('remainingTime returns Duration', () {
      expect(tActiveChallenge.remainingTime, isA<Duration>());
    });
  });
}
