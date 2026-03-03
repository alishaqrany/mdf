import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/social/domain/entities/social_entities.dart';
import 'package:mdf_app/features/social/domain/repositories/social_repository.dart';
import 'package:mdf_app/features/social/presentation/bloc/study_groups_bloc.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late StudyGroupsBloc bloc;

  final tGroup = StudyGroup(
    id: 1,
    name: 'Math Study Group',
    description: 'Weekly math sessions',
    courseId: 101,
    courseName: 'Mathematics',
    createdBy: 1,
    creatorName: 'Ahmad',
    isPublic: true,
    memberCount: 5,
    maxMembers: 30,
    createdAt: DateTime(2024, 3, 1),
  );

  final tMember = GroupMember(
    userId: 1,
    fullName: 'Ahmad Ali',
    role: GroupMemberRole.admin,
    joinedAt: DateTime(2024, 3, 1),
  );

  setUp(() {
    mockRepository = MockSocialRepository();
    bloc = StudyGroupsBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is StudyGroupsInitial', () {
    expect(bloc.state, isA<StudyGroupsInitial>());
  });

  group('LoadStudyGroups', () {
    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getStudyGroups(courseId: any(named: 'courseId')),
        ).thenAnswer((_) async => Right([tGroup]));
        return bloc;
      },
      act: (b) => b.add(const LoadStudyGroups()),
      expect: () => [
        isA<StudyGroupsLoading>(),
        isA<StudyGroupsLoaded>().having((s) => s.groups.length, 'count', 1),
      ],
    );

    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getStudyGroups(courseId: any(named: 'courseId')),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Groups error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadStudyGroups()),
      expect: () => [isA<StudyGroupsLoading>(), isA<StudyGroupsError>()],
    );
  });

  group('LoadGroupDetail', () {
    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [Loading, DetailLoaded] on success',
      build: () {
        when(
          () => mockRepository.getGroupDetail(1),
        ).thenAnswer((_) async => Right(tGroup));
        when(
          () => mockRepository.getGroupMembers(1),
        ).thenAnswer((_) async => Right([tMember]));
        return bloc;
      },
      act: (b) => b.add(const LoadGroupDetail(1)),
      expect: () => [
        isA<StudyGroupsLoading>(),
        isA<StudyGroupDetailLoaded>()
            .having((s) => s.group.name, 'name', 'Math Study Group')
            .having((s) => s.members.length, 'members', 1),
      ],
    );
  });

  group('CreateStudyGroup', () {
    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [Loading, Created] on success',
      build: () {
        when(
          () => mockRepository.createStudyGroup(
            name: any(named: 'name'),
            courseId: any(named: 'courseId'),
            description: any(named: 'description'),
            isPublic: any(named: 'isPublic'),
            maxMembers: any(named: 'maxMembers'),
          ),
        ).thenAnswer((_) async => Right(tGroup));
        return bloc;
      },
      act: (b) => b.add(
        const CreateStudyGroup(
          name: 'Math Study Group',
          courseId: 101,
          description: 'Weekly math sessions',
        ),
      ),
      expect: () => [isA<StudyGroupsLoading>(), isA<StudyGroupCreated>()],
    );
  });

  group('JoinStudyGroup', () {
    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.joinStudyGroup(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const JoinStudyGroup(1)),
      expect: () => [isA<StudyGroupActionSuccess>()],
    );
  });

  group('LeaveStudyGroup', () {
    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.leaveStudyGroup(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const LeaveStudyGroup(1)),
      expect: () => [isA<StudyGroupActionSuccess>()],
    );
  });

  group('DeleteStudyGroup', () {
    blocTest<StudyGroupsBloc, StudyGroupsState>(
      'emits [ActionSuccess] on success',
      build: () {
        when(
          () => mockRepository.deleteStudyGroup(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const DeleteStudyGroup(1)),
      expect: () => [isA<StudyGroupActionSuccess>()],
    );
  });
}
