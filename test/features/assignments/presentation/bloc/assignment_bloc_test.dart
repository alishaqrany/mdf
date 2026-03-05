import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/assignments/domain/entities/assignment.dart';
import 'package:mdf_app/features/assignments/domain/repositories/assignment_repository.dart';
import 'package:mdf_app/features/assignments/presentation/bloc/assignment_bloc.dart';

class MockAssignmentRepository extends Mock implements AssignmentRepository {}

void main() {
  late MockAssignmentRepository mockRepository;
  late AssignmentBloc bloc;

  const tAssignment = Assignment(
    id: 1,
    courseId: 10,
    name: 'Test Assignment',
    intro: 'Assignment intro',
  );

  const tSubmission = AssignmentSubmission(
    id: 1,
    userId: 5,
    assignmentId: 1,
    status: 'submitted',
    timeCreated: 1700000000,
  );

  const tGrade = AssignmentGrade(
    id: 1,
    userId: 5,
    assignmentId: 1,
    grade: 85.0,
  );

  setUp(() {
    mockRepository = MockAssignmentRepository();
    bloc = AssignmentBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is AssignmentInitial', () {
    expect(bloc.state, isA<AssignmentInitial>());
  });

  group('LoadAssignments', () {
    blocTest<AssignmentBloc, AssignmentState>(
      'emits [Loading, AssignmentsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getAssignmentsByCourse(10),
        ).thenAnswer((_) async => const Right([tAssignment]));
        return bloc;
      },
      act: (b) => b.add(const LoadAssignments(courseId: 10)),
      expect: () => [
        isA<AssignmentLoading>(),
        isA<AssignmentsLoaded>().having(
          (s) => s.assignments.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<AssignmentBloc, AssignmentState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getAssignmentsByCourse(10),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Network error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadAssignments(courseId: 10)),
      expect: () => [
        isA<AssignmentLoading>(),
        isA<AssignmentError>().having(
          (s) => s.message,
          'message',
          'Network error',
        ),
      ],
    );
  });

  group('LoadSubmissions', () {
    blocTest<AssignmentBloc, AssignmentState>(
      'emits [Loading, SubmissionsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getSubmissions(1),
        ).thenAnswer((_) async => const Right([tSubmission]));
        return bloc;
      },
      act: (b) => b.add(const LoadSubmissions(assignmentId: 1)),
      expect: () => [
        isA<AssignmentLoading>(),
        isA<SubmissionsLoaded>().having(
          (s) => s.submissions.first.isSubmitted,
          'isSubmitted',
          true,
        ),
      ],
    );
  });

  group('LoadGrades', () {
    blocTest<AssignmentBloc, AssignmentState>(
      'emits AssignmentGradesLoaded on success',
      build: () {
        when(
          () => mockRepository.getGrades(1),
        ).thenAnswer((_) async => const Right([tGrade]));
        return bloc;
      },
      act: (b) => b.add(const LoadGrades(assignmentId: 1)),
      expect: () => [
        isA<AssignmentGradesLoaded>().having(
          (s) => s.grades.first.grade,
          'grade',
          85.0,
        ),
      ],
    );
  });

  group('SaveGradeEvent', () {
    blocTest<AssignmentBloc, AssignmentState>(
      'emits [Loading, GradeSaved] on success',
      build: () {
        when(
          () => mockRepository.saveGrade(1, 5, 90.0, 'Good job'),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const SaveGradeEvent(
        assignmentId: 1,
        userId: 5,
        grade: 90.0,
        feedback: 'Good job',
      )),
      expect: () => [
        isA<AssignmentLoading>(),
        isA<GradeSaved>(),
      ],
    );

    blocTest<AssignmentBloc, AssignmentState>(
      'emits [Loading, Error] when save grade fails',
      build: () {
        when(
          () => mockRepository.saveGrade(1, 5, 90.0, null),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Save failed')),
        );
        return bloc;
      },
      act: (b) => b.add(const SaveGradeEvent(
        assignmentId: 1,
        userId: 5,
        grade: 90.0,
      )),
      expect: () => [
        isA<AssignmentLoading>(),
        isA<AssignmentError>().having(
          (s) => s.message,
          'message',
          'Save failed',
        ),
      ],
    );
  });

  group('SubmitAssignment', () {
    blocTest<AssignmentBloc, AssignmentState>(
      'emits [Loading, AssignmentSubmitted] on success',
      build: () {
        when(
          () => mockRepository.submitForGrading(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const SubmitAssignment(assignmentId: 1)),
      expect: () => [
        isA<AssignmentLoading>(),
        isA<AssignmentSubmitted>(),
      ],
    );
  });
}
