import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/gamification/domain/entities/gamification_entities.dart';
import 'package:mdf_app/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:mdf_app/features/gamification/presentation/bloc/badges_bloc.dart';

class MockGamificationRepository extends Mock
    implements GamificationRepository {}

void main() {
  late MockGamificationRepository mockRepository;
  late BadgesBloc bloc;

  const tBadge = Badge(
    id: 1,
    name: 'First Steps',
    description: 'Complete your first course',
    iconName: 'star',
    category: BadgeCategory.courses,
    rarity: BadgeRarity.common,
    requiredPoints: 100,
    isEarned: true,
    earnedPercentage: 45.0,
  );

  const tLockedBadge = Badge(
    id: 2,
    name: 'Quiz Master',
    description: 'Score 100% on 5 quizzes',
    iconName: 'quiz',
    category: BadgeCategory.quizzes,
    rarity: BadgeRarity.rare,
    requiredPoints: 500,
    isEarned: false,
    earnedPercentage: 10.0,
  );

  setUp(() {
    mockRepository = MockGamificationRepository();
    bloc = BadgesBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is BadgesInitial', () {
    expect(bloc.state, isA<BadgesInitial>());
  });

  group('LoadAllBadges', () {
    blocTest<BadgesBloc, BadgesState>(
      'emits [Loading, Loaded] with earned and locked badges',
      build: () {
        when(
          () => mockRepository.getAllBadges(1),
        ).thenAnswer((_) async => const Right([tBadge, tLockedBadge]));
        return bloc;
      },
      act: (b) => b.add(const LoadAllBadges(1)),
      expect: () => [
        isA<BadgesLoading>(),
        isA<BadgesLoaded>()
            .having((s) => s.allBadges.length, 'all', 2)
            .having((s) => s.earned.length, 'earned', 1)
            .having((s) => s.locked.length, 'locked', 1),
      ],
    );

    blocTest<BadgesBloc, BadgesState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getAllBadges(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Badges error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadAllBadges(1)),
      expect: () => [isA<BadgesLoading>(), isA<BadgesError>()],
    );
  });

  group('LoadBadgeDetail', () {
    blocTest<BadgesBloc, BadgesState>(
      'emits [Loading, DetailLoaded] on success',
      build: () {
        when(
          () => mockRepository.getBadgeDetail(1, 1),
        ).thenAnswer((_) async => const Right(tBadge));
        return bloc;
      },
      act: (b) => b.add(const LoadBadgeDetail(badgeId: 1, userId: 1)),
      expect: () => [
        isA<BadgesLoading>(),
        isA<BadgeDetailLoaded>().having(
          (s) => s.badge.name,
          'name',
          'First Steps',
        ),
      ],
    );
  });

  group('Badge entity', () {
    test('isEarned correctly set', () {
      expect(tBadge.isEarned, isTrue);
      expect(tLockedBadge.isEarned, isFalse);
    });

    test('rarity levels', () {
      expect(tBadge.rarity, BadgeRarity.common);
      expect(tLockedBadge.rarity, BadgeRarity.rare);
    });

    test('category is correct', () {
      expect(tBadge.category, BadgeCategory.courses);
      expect(tLockedBadge.category, BadgeCategory.quizzes);
    });
  });
}
