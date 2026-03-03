import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/gamification/domain/entities/gamification_entities.dart';
import 'package:mdf_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:mdf_app/features/gamification/presentation/bloc/points_bloc.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepository;
  late PointsBloc bloc;

  const tUserPoints = UserPoints(
    userId: 1,
    fullName: 'Ahmad Ali',
    totalPoints: 500,
    level: 3,
    currentLevelPoints: 200,
    nextLevelPoints: 300,
    currentStreak: 5,
    longestStreak: 10,
    rank: 3,
    totalUsers: 50,
  );

  final tTransaction = PointTransaction(
    id: 1,
    userId: 1,
    points: 10,
    action: PointAction.dailyLogin,
    description: 'Daily login bonus',
    createdAt: DateTime(2024, 3, 15),
  );

  setUp(() {
    mockRepository = MockGamificationRepository();
    bloc = PointsBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is PointsInitial', () {
    expect(bloc.state, isA<PointsInitial>());
  });

  group('LoadUserPoints', () {
    blocTest<PointsBloc, PointsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getUserPoints(1),
        ).thenAnswer((_) async => const Right(tUserPoints));
        return bloc;
      },
      act: (b) => b.add(const LoadUserPoints(1)),
      expect: () => [
        isA<PointsLoading>(),
        isA<PointsLoaded>().having(
          (s) => s.userPoints.totalPoints,
          'totalPoints',
          500,
        ),
      ],
    );

    blocTest<PointsBloc, PointsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getUserPoints(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Points error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadUserPoints(1)),
      expect: () => [isA<PointsLoading>(), isA<PointsError>()],
    );
  });

  group('LoadPointHistory', () {
    blocTest<PointsBloc, PointsState>(
      'emits [Loaded with history] on success (no Loading state)',
      build: () {
        when(
          () => mockRepository.getUserPoints(1),
        ).thenAnswer((_) async => const Right(tUserPoints));
        when(
          () => mockRepository.getPointHistory(1),
        ).thenAnswer((_) async => Right([tTransaction]));
        return bloc;
      },
      act: (b) => b.add(const LoadPointHistory(1)),
      expect: () => [
        isA<PointsLoaded>().having(
          (s) => s.history.length,
          'history length',
          1,
        ),
      ],
    );
  });

  group('RecordDailyLogin', () {
    blocTest<PointsBloc, PointsState>(
      'emits [Loaded] with updated points on success',
      build: () {
        when(
          () => mockRepository.recordDailyLogin(1),
        ).thenAnswer((_) async => const Right(tUserPoints));
        return bloc;
      },
      act: (b) => b.add(const RecordDailyLogin(1)),
      expect: () => [isA<PointsLoaded>()],
    );

    blocTest<PointsBloc, PointsState>(
      'emits nothing on failure',
      build: () {
        when(() => mockRepository.recordDailyLogin(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Login failed')),
        );
        return bloc;
      },
      act: (b) => b.add(const RecordDailyLogin(1)),
      expect: () => [],
    );
  });

  group('UserPoints entity', () {
    test('levelProgress returns correct value', () {
      expect(tUserPoints.levelProgress, closeTo(0.666, 0.01));
    });

    test('levelTitle returns non-empty string', () {
      expect(tUserPoints.levelTitle, isNotEmpty);
    });
  });
}
