import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/quizzes/domain/entities/quiz.dart';
import 'package:mdf_app/features/quizzes/domain/repositories/quiz_repository.dart';
import 'package:mdf_app/features/quizzes/presentation/bloc/quiz_bloc.dart';

class MockQuizRepository extends Mock implements QuizRepository {}

void main() {
  late MockQuizRepository mockRepository;
  late QuizBloc bloc;

  const tQuiz = Quiz(
    id: 1,
    courseId: 10,
    name: 'Midterm Quiz',
    intro: 'Chapter 1-5',
    timeLimit: 3600,
    grade: 100.0,
  );

  const tAttempt = QuizAttempt(
    id: 1,
    quizId: 1,
    userId: 5,
    attempt: 1,
    state: 'inprogress',
    timeStart: 1700000000,
  );

  const tQuestion = QuizQuestion(
    slot: 1,
    type: 'multichoice',
    html: '<p>What is 2+2?</p>',
    sequenceCheck: 1,
    flagged: false,
    state: '',
    mark: null,
  );

  setUp(() {
    mockRepository = MockQuizRepository();
    bloc = QuizBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is QuizInitial', () {
    expect(bloc.state, isA<QuizInitial>());
  });

  group('LoadQuizzes', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, QuizzesLoaded] on success',
      build: () {
        when(
          () => mockRepository.getQuizzesByCourse(10),
        ).thenAnswer((_) async => const Right([tQuiz]));
        return bloc;
      },
      act: (b) => b.add(const LoadQuizzes(courseId: 10)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizzesLoaded>().having(
          (s) => s.quizzes.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getQuizzesByCourse(10),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Connection error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadQuizzes(courseId: 10)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizError>().having(
          (s) => s.message,
          'message',
          'Connection error',
        ),
      ],
    );
  });

  group('LoadQuizAttempts', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, AttemptsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getUserAttempts(1, 5),
        ).thenAnswer((_) async => const Right([tAttempt]));
        return bloc;
      },
      act: (b) => b.add(const LoadQuizAttempts(quizId: 1, userId: 5)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizAttemptsLoaded>().having(
          (s) => s.attempts.first.isInProgress,
          'inProgress',
          true,
        ),
      ],
    );
  });

  group('StartQuizAttempt', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, AttemptStarted] on success',
      build: () {
        when(
          () => mockRepository.startAttempt(1),
        ).thenAnswer((_) async => const Right(tAttempt));
        return bloc;
      },
      act: (b) => b.add(const StartQuizAttempt(quizId: 1)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizAttemptStarted>().having(
          (s) => s.attempt.id,
          'attemptId',
          1,
        ),
      ],
    );
  });

  group('LoadAttemptQuestions', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, QuestionsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getAttemptData(1, 0),
        ).thenAnswer((_) async => const Right([tQuestion]));
        return bloc;
      },
      act: (b) => b.add(const LoadAttemptQuestions(attemptId: 1, page: 0)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizQuestionsLoaded>().having(
          (s) => s.questions.length,
          'count',
          1,
        ),
      ],
    );
  });

  group('SubmitQuizAttempt', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Submitted] on success',
      build: () {
        when(
          () => mockRepository.submitAttempt(1),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(const SubmitQuizAttempt(attemptId: 1)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizAttemptSubmitted>(),
      ],
    );

    blocTest<QuizBloc, QuizState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.submitAttempt(1),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Submit failed')),
        );
        return bloc;
      },
      act: (b) => b.add(const SubmitQuizAttempt(attemptId: 1)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizError>().having(
          (s) => s.message,
          'message',
          'Submit failed',
        ),
      ],
    );
  });

  group('LoadAttemptReview', () {
    blocTest<QuizBloc, QuizState>(
      'emits [Loading, ReviewLoaded] on success',
      build: () {
        when(
          () => mockRepository.getAttemptReview(1),
        ).thenAnswer((_) async => const Right([tQuestion]));
        return bloc;
      },
      act: (b) => b.add(const LoadAttemptReview(attemptId: 1)),
      expect: () => [
        isA<QuizLoading>(),
        isA<QuizReviewLoaded>().having(
          (s) => s.questions.length,
          'count',
          1,
        ),
      ],
    );
  });
}
