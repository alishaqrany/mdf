import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/course_content/domain/entities/course_content.dart';
import 'package:mdf_app/features/course_content/domain/repositories/course_content_repository.dart';
import 'package:mdf_app/features/course_content/presentation/bloc/course_content_bloc.dart';

class MockCourseContentRepository extends Mock
    implements CourseContentRepository {}

void main() {
  late MockCourseContentRepository mockRepository;
  late CourseContentBloc bloc;

  const tModule = CourseModule(
    id: 1,
    name: 'Lesson 1',
    modName: 'page',
    instance: 1,
  );

  final tSection = CourseSection(
    id: 1,
    name: 'Section 1',
    sectionNumber: 0,
    modules: const [tModule],
  );

  setUp(() {
    mockRepository = MockCourseContentRepository();
    bloc = CourseContentBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is CourseContentInitial', () {
    expect(bloc.state, isA<CourseContentInitial>());
  });

  group('LoadCourseContent', () {
    blocTest<CourseContentBloc, CourseContentState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getCourseContents(10),
        ).thenAnswer((_) async => Right([tSection]));
        return bloc;
      },
      act: (b) => b.add(const LoadCourseContent(courseId: 10)),
      expect: () => [
        isA<CourseContentLoading>(),
        isA<CourseContentLoaded>().having(
          (s) => s.sections.length,
          'sections',
          1,
        ),
      ],
    );

    blocTest<CourseContentBloc, CourseContentState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getCourseContents(10),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to load')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadCourseContent(courseId: 10)),
      expect: () => [
        isA<CourseContentLoading>(),
        isA<CourseContentError>().having(
          (s) => s.message,
          'message',
          'Failed to load',
        ),
      ],
    );
  });

  group('ToggleActivityCompletion', () {
    blocTest<CourseContentBloc, CourseContentState>(
      'emits [Loading, Loaded] after toggle then reload',
      build: () {
        when(
          () => mockRepository.updateActivityCompletion(1, true),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getCourseContents(10),
        ).thenAnswer((_) async => Right([tSection]));
        return bloc;
      },
      act: (b) => b.add(const ToggleActivityCompletion(
        cmId: 1,
        completed: true,
        courseId: 10,
      )),
      expect: () => [
        isA<CourseContentLoading>(),
        isA<CourseContentLoaded>(),
      ],
    );
  });
}
