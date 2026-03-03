import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/search/domain/entities/search_result.dart';
import 'package:mdf_app/features/search/domain/repositories/search_repository.dart';
import 'package:mdf_app/features/search/presentation/bloc/search_bloc.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late MockSearchRepository mockRepository;
  late SharedPreferences prefs;
  late SearchBloc bloc;

  const tCourseResult = SearchResult(
    id: 1,
    title: 'Mathematics 101',
    subtitle: 'Introduction to Math',
    type: SearchResultType.course,
  );

  const tUserResult = SearchResult(
    id: 2,
    title: 'Ahmad Ali',
    type: SearchResultType.user,
  );

  final tResults = [tCourseResult, tUserResult];

  setUp(() async {
    mockRepository = MockSearchRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bloc = SearchBloc(repository: mockRepository, prefs: prefs);
  });

  tearDown(() => bloc.close());

  test('initial state is SearchInitial', () {
    expect(bloc.state, isA<SearchInitial>());
  });

  group('PerformSearch', () {
    blocTest<SearchBloc, SearchState>(
      'emits [Loading, Results] on successful searchAll',
      build: () {
        when(
          () => mockRepository.searchAll('math'),
        ).thenAnswer((_) async => Right(tResults));
        return bloc;
      },
      act: (b) => b.add(const PerformSearch(query: 'math')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchResults>().having((s) => s.results.length, 'count', 2),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [Loading, Results] with courses filter',
      build: () {
        when(
          () => mockRepository.searchCourses('math'),
        ).thenAnswer((_) async => const Right([tCourseResult]));
        return bloc;
      },
      act: (b) => b.add(
        const PerformSearch(query: 'math', filter: SearchFilter.courses),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchResults>().having(
          (s) => s.filter,
          'filter',
          SearchFilter.courses,
        ),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [Loading, Results] with users filter',
      build: () {
        when(
          () => mockRepository.searchUsers('ahmad'),
        ).thenAnswer((_) async => const Right([tUserResult]));
        return bloc;
      },
      act: (b) => b.add(
        const PerformSearch(query: 'ahmad', filter: SearchFilter.users),
      ),
      wait: const Duration(milliseconds: 500),
      expect: () => [isA<SearchLoading>(), isA<SearchResults>()],
    );

    blocTest<SearchBloc, SearchState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.searchAll('test')).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Search failed')),
        );
        return bloc;
      },
      act: (b) => b.add(const PerformSearch(query: 'test')),
      wait: const Duration(milliseconds: 500),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchError>().having((s) => s.message, 'message', 'Search failed'),
      ],
    );
  });

  group('ClearSearch', () {
    blocTest<SearchBloc, SearchState>(
      'emits SearchInitial on clear',
      build: () => bloc,
      act: (b) => b.add(const ClearSearch()),
      expect: () => [isA<SearchInitial>()],
    );
  });

  group('LoadSearchHistory', () {
    blocTest<SearchBloc, SearchState>(
      'emits SearchInitial with recent searches',
      build: () => bloc,
      act: (b) => b.add(const LoadSearchHistory()),
      expect: () => [isA<SearchInitial>()],
    );
  });

  group('SearchResult entity', () {
    test('equality based on id and type', () {
      expect(tCourseResult, tCourseResult);
    });

    test('type is course', () {
      expect(tCourseResult.type, SearchResultType.course);
    });

    test('type is user', () {
      expect(tUserResult.type, SearchResultType.user);
    });
  });
}
