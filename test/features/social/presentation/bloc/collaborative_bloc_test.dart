import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/social/domain/entities/social_entities.dart';
import 'package:mdf_app/features/social/domain/repositories/social_repository.dart';
import 'package:mdf_app/features/social/presentation/bloc/collaborative_bloc.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late CollaborativeBloc bloc;

  final tSession = CollaborativeSession(
    id: 1,
    title: 'Math Study Session',
    description: 'Review chapter 5',
    groupId: 1,
    groupName: 'Math Study Group',
    createdBy: 1,
    creatorName: 'Ahmad',
    startTime: DateTime(2024, 3, 20, 14, 0),
    endTime: DateTime(2024, 3, 20, 16, 0),
    participantCount: 3,
    maxParticipants: 20,
    status: SessionStatus.scheduled,
    topic: 'Calculus',
  );

  final tNote = SessionNote(
    id: 1,
    sessionId: 1,
    authorId: 1,
    authorName: 'Ahmad',
    content: 'Key formula: integration by parts',
    createdAt: DateTime(2024, 3, 20, 14, 30),
  );

  setUp(() {
    mockRepository = MockSocialRepository();
    bloc = CollaborativeBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is CollaborativeInitial', () {
    expect(bloc.state, isA<CollaborativeInitial>());
  });

  group('LoadGroupSessions', () {
    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [Loading, SessionsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getGroupSessions(1),
        ).thenAnswer((_) async => Right([tSession]));
        return bloc;
      },
      act: (b) => b.add(const LoadGroupSessions(1)),
      expect: () => [
        isA<CollaborativeLoading>(),
        isA<CollaborativeSessionsLoaded>().having(
          (s) => s.sessions.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getGroupSessions(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Sessions error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadGroupSessions(1)),
      expect: () => [isA<CollaborativeLoading>(), isA<CollaborativeError>()],
    );
  });

  group('CreateSession', () {
    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [Loading, SessionCreated] on success',
      build: () {
        when(
          () => mockRepository.createSession(
            title: any(named: 'title'),
            groupId: any(named: 'groupId'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            description: any(named: 'description'),
            topic: any(named: 'topic'),
          ),
        ).thenAnswer((_) async => Right(tSession));
        return bloc;
      },
      act: (b) => b.add(
        CreateSession(
          title: 'Math Study Session',
          groupId: 1,
          startTime: DateTime(2024, 3, 20, 14, 0),
          topic: 'Calculus',
        ),
      ),
      expect: () => [
        isA<CollaborativeLoading>(),
        isA<CollaborativeSessionCreated>(),
      ],
    );
  });

  group('JoinSession', () {
    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.joinSession(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const JoinSession(1)),
      expect: () => [isA<CollaborativeActionSuccess>()],
    );
  });

  group('LeaveSession', () {
    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.leaveSession(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const LeaveSession(1)),
      expect: () => [isA<CollaborativeActionSuccess>()],
    );
  });

  group('EndSession', () {
    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.endSession(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const EndSession(1)),
      expect: () => [isA<CollaborativeActionSuccess>()],
    );
  });

  group('AddSessionNoteEvent', () {
    blocTest<CollaborativeBloc, CollaborativeState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.addSessionNote(
            1,
            'Key formula: integration by parts',
          ),
        ).thenAnswer((_) async => Right(tNote));
        return bloc;
      },
      act: (b) => b.add(
        const AddSessionNoteEvent(
          sessionId: 1,
          content: 'Key formula: integration by parts',
        ),
      ),
      expect: () => [isA<CollaborativeActionSuccess>()],
    );
  });

  group('CollaborativeSession entity', () {
    test('status is scheduled', () {
      expect(tSession.status, SessionStatus.scheduled);
    });

    test('participantCount less than maxParticipants', () {
      expect(tSession.participantCount, lessThan(tSession.maxParticipants));
    });
  });
}
