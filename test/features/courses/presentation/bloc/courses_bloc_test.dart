import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/courses/domain/entities/course.dart';
import 'package:mdf_app/features/courses/domain/usecases/get_enrolled_courses_usecase.dart';
import 'package:mdf_app/features/courses/domain/usecases/search_courses_usecase.dart';
import 'package:mdf_app/features/courses/presentation/bloc/courses_bloc.dart';

class MockGetEnrolledCourses extends Mock
    implements GetEnrolledCoursesUseCase {}

class MockSearchCourses extends Mock implements SearchCoursesUseCase {}

void main() {
  late MockGetEnrolledCourses mockGetEnrolled;
  late MockSearchCourses mockSearch;
  late CoursesBloc bloc;

  const tCourses = [
    Course(id: 1, shortName: 'MATH101', fullName: 'Math 101'),
    Course(id: 2, shortName: 'SCI201', fullName: 'Science 201'),
  ];

  setUp(() {
    mockGetEnrolled = MockGetEnrolledCourses();
    mockSearch = MockSearchCourses();
    bloc = CoursesBloc(
      getEnrolledCourses: mockGetEnrolled,
      searchCourses: mockSearch,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is CoursesInitial', () {
    expect(bloc.state, isA<CoursesInitial>());
  });

  group('LoadEnrolledCourses', () {
    blocTest<CoursesBloc, CoursesState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockGetEnrolled(10),
        ).thenAnswer((_) async => const Right(tCourses));
        return bloc;
      },
      act: (b) => b.add(const LoadEnrolledCourses(userId: 10)),
      expect: () => [
        isA<CoursesLoading>(),
        isA<CoursesLoaded>().having((s) => s.courses.length, 'count', 2),
      ],
    );

    blocTest<CoursesBloc, CoursesState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockGetEnrolled(10),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed')));
        return bloc;
      },
      act: (b) => b.add(const LoadEnrolledCourses(userId: 10)),
      expect: () => [
        isA<CoursesLoading>(),
        isA<CoursesError>().having((s) => s.message, 'msg', 'Failed'),
      ],
    );
  });

  group('SearchCoursesEvent', () {
    blocTest<CoursesBloc, CoursesState>(
      'emits [Loading, SearchResults] on success',
      build: () {
        when(
          () => mockSearch('math'),
        ).thenAnswer((_) async => const Right(tCourses));
        return bloc;
      },
      act: (b) => b.add(const SearchCoursesEvent(query: 'math')),
      expect: () => [
        isA<CoursesLoading>(),
        isA<CoursesSearchResults>()
            .having((s) => s.query, 'query', 'math')
            .having((s) => s.courses.length, 'count', 2),
      ],
    );

    blocTest<CoursesBloc, CoursesState>(
      'emits [Loading, Error] on search failure',
      build: () {
        when(
          () => mockSearch('xyz'),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (b) => b.add(const SearchCoursesEvent(query: 'xyz')),
      expect: () => [isA<CoursesLoading>(), isA<CoursesError>()],
    );
  });

  group('RefreshCourses', () {
    blocTest<CoursesBloc, CoursesState>(
      'emits [Loaded] without Loading on refresh success',
      build: () {
        when(
          () => mockGetEnrolled(10),
        ).thenAnswer((_) async => const Right(tCourses));
        return bloc;
      },
      act: (b) => b.add(const RefreshCourses(userId: 10)),
      expect: () => [
        isA<CoursesLoaded>().having((s) => s.courses.length, 'count', 2),
      ],
    );
  });

  group('Course entity', () {
    test('equality based on id, shortName, fullName', () {
      const a = Course(id: 1, shortName: 'MATH101', fullName: 'Math 101');
      const b = Course(
        id: 1,
        shortName: 'MATH101',
        fullName: 'Math 101',
        progress: 50,
      );
      expect(a, equals(b));
    });
  });
}
