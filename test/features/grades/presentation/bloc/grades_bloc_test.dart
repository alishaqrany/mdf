import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/grades/domain/entities/grade.dart';
import 'package:mdf_app/features/grades/domain/repositories/grade_repository.dart';
import 'package:mdf_app/features/grades/presentation/bloc/grades_bloc.dart';

class MockGradeRepository extends Mock implements GradeRepository {}

void main() {
  late MockGradeRepository mockRepository;
  late GradesBloc gradesBloc;

  const tGradeItems = [
    GradeItem(id: 1, itemName: 'Quiz 1', gradeRaw: 85, gradeMax: 100),
    GradeItem(id: 2, itemName: 'Assignment 1', gradeRaw: 92, gradeMax: 100),
  ];

  const tCourseGrades = [
    CourseGrade(courseId: 1, courseName: 'Math', grade: 88.5),
    CourseGrade(courseId: 2, courseName: 'Science', grade: 75.0, rank: 3),
  ];

  setUp(() {
    mockRepository = MockGradeRepository();
    gradesBloc = GradesBloc(repository: mockRepository);
  });

  tearDown(() => gradesBloc.close());

  test('initial state is GradesInitial', () {
    expect(gradesBloc.state, isA<GradesInitial>());
  });

  // ─── LoadCourseGradeItems ───
  group('LoadCourseGradeItems', () {
    const tEvent = LoadCourseGradeItems(courseId: 1, userId: 10);

    blocTest<GradesBloc, GradesState>(
      'emits [GradesLoading, GradeItemsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getGradeItems(1, 10),
        ).thenAnswer((_) async => const Right(tGradeItems));
        return gradesBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<GradesLoading>(),
        isA<GradeItemsLoaded>().having(
          (s) => s.items.length,
          'items length',
          2,
        ),
      ],
    );

    blocTest<GradesBloc, GradesState>(
      'emits [GradesLoading, GradesError] on failure',
      build: () {
        when(() => mockRepository.getGradeItems(1, 10)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return gradesBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<GradesLoading>(),
        isA<GradesError>().having((s) => s.message, 'message', 'Server error'),
      ],
    );
  });

  // ─── LoadAllCourseGrades ───
  group('LoadAllCourseGrades', () {
    const tEvent = LoadAllCourseGrades(userId: 10);

    blocTest<GradesBloc, GradesState>(
      'emits [GradesLoading, CourseGradesLoaded] on success',
      build: () {
        when(
          () => mockRepository.getCourseGrades(10),
        ).thenAnswer((_) async => const Right(tCourseGrades));
        return gradesBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<GradesLoading>(),
        isA<CourseGradesLoaded>().having(
          (s) => s.grades.length,
          'grades length',
          2,
        ),
      ],
    );

    blocTest<GradesBloc, GradesState>(
      'emits [GradesLoading, GradesError] on failure',
      build: () {
        when(
          () => mockRepository.getCourseGrades(10),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return gradesBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<GradesLoading>(),
        isA<GradesError>().having(
          (s) => s.message,
          'message',
          'No internet connection',
        ),
      ],
    );
  });

  // ─── Entity tests ───
  group('GradeItem entity', () {
    test('equality based on id and itemName', () {
      const a = GradeItem(id: 1, itemName: 'Quiz 1');
      const b = GradeItem(id: 1, itemName: 'Quiz 1', gradeRaw: 90);
      expect(a, equals(b));
    });
  });

  group('CourseGrade entity', () {
    test('equality based on courseId', () {
      const a = CourseGrade(courseId: 1, courseName: 'Math');
      const b = CourseGrade(courseId: 1, courseName: 'Math', grade: 95);
      expect(a, equals(b));
    });
  });
}
