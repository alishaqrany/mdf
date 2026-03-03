import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/gamification/domain/entities/gamification_entities.dart';
import 'package:mdf_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:mdf_app/features/gamification/presentation/bloc/leaderboard_bloc.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepository;
  late LeaderboardBloc bloc;

  const tEntry = LeaderboardEntry(
    rank: 1,
    userId: 1,
    fullName: 'Ahmad Ali',
    points: 1000,
    level: 5,
    badgeCount: 10,
    currentStreak: 7,
    isCurrentUser: true,
  );

  const tEntry2 = LeaderboardEntry(
    rank: 2,
    userId: 2,
    fullName: 'Sara Mohammed',
    points: 900,
    level: 4,
    badgeCount: 8,
    currentStreak: 3,
  );

  setUpAll(() {
    registerFallbackValue(LeaderboardPeriod.allTime);
  });

  setUp(() {
    mockRepository = MockGamificationRepository();
    bloc = LeaderboardBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is LeaderboardInitial', () {
    expect(bloc.state, isA<LeaderboardInitial>());
  });

  group('LoadLeaderboard', () {
    blocTest<LeaderboardBloc, LeaderboardState>(
      'emits [Loading, Loaded] on success with allTime period',
      build: () {
        when(
          () => mockRepository.getLeaderboard(
            period: any(named: 'period'),
            courseId: any(named: 'courseId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right([tEntry, tEntry2]));
        return bloc;
      },
      act: (b) => b.add(const LoadLeaderboard()),
      expect: () => [
        isA<LeaderboardLoading>(),
        isA<LeaderboardLoaded>()
            .having((s) => s.entries.length, 'entries', 2)
            .having((s) => s.period, 'period', LeaderboardPeriod.allTime),
      ],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'emits [Loading, Loaded] with weekly period',
      build: () {
        when(
          () => mockRepository.getLeaderboard(
            period: any(named: 'period'),
            courseId: any(named: 'courseId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right([tEntry]));
        return bloc;
      },
      act: (b) =>
          b.add(const LoadLeaderboard(period: LeaderboardPeriod.weekly)),
      expect: () => [
        isA<LeaderboardLoading>(),
        isA<LeaderboardLoaded>().having(
          (s) => s.period,
          'period',
          LeaderboardPeriod.weekly,
        ),
      ],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getLeaderboard(
            period: any(named: 'period'),
            courseId: any(named: 'courseId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Leaderboard error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadLeaderboard()),
      expect: () => [isA<LeaderboardLoading>(), isA<LeaderboardError>()],
    );

    blocTest<LeaderboardBloc, LeaderboardState>(
      'identifies current user in loaded entries',
      build: () {
        when(
          () => mockRepository.getLeaderboard(
            period: any(named: 'period'),
            courseId: any(named: 'courseId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right([tEntry, tEntry2]));
        return bloc;
      },
      act: (b) => b.add(const LoadLeaderboard()),
      expect: () => [
        isA<LeaderboardLoading>(),
        isA<LeaderboardLoaded>().having(
          (s) => s.currentUser?.userId,
          'currentUser',
          1,
        ),
      ],
    );
  });

  group('ChangePeriod', () {
    blocTest<LeaderboardBloc, LeaderboardState>(
      'reloads leaderboard with new period',
      build: () {
        when(
          () => mockRepository.getLeaderboard(
            period: any(named: 'period'),
            courseId: any(named: 'courseId'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right([tEntry]));
        return bloc;
      },
      act: (b) => b.add(const ChangePeriod(LeaderboardPeriod.daily)),
      expect: () => [isA<LeaderboardLoading>(), isA<LeaderboardLoaded>()],
    );
  });

  group('LeaderboardEntry entity', () {
    test('isCurrentUser flag', () {
      expect(tEntry.isCurrentUser, isTrue);
      expect(tEntry2.isCurrentUser, isFalse);
    });

    test('equatable works on same data', () {
      expect(tEntry, tEntry);
    });
  });
}
