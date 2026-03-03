import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/ai/domain/entities/ai_entities.dart';
import 'package:mdf_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:mdf_app/features/ai/presentation/bloc/ai_insights_bloc.dart';

class MockAiRepository extends Mock implements AiRepository {}

void main() {
  late MockAiRepository mockRepository;
  late AiInsightsBloc bloc;

  const tPrediction = PerformancePrediction(
    courseId: 101,
    courseName: 'Mathematics',
    predictedGrade: 85.0,
    riskLevel: RiskLevel.low,
    strengths: ['Problem solving', 'Consistency'],
    weaknesses: ['Time management'],
    suggestions: ['Practice more timed exercises'],
    completionLikelihood: 0.92,
  );

  const tRecommendation = CourseRecommendation(
    courseId: 201,
    courseName: 'Advanced Statistics',
    confidenceScore: 0.87,
    reason: RecommendationReason.sameCategory,
    reasonText: 'Based on your math performance',
  );

  const tInsights = StudentInsights(
    userId: 1,
    overallPerformance: 82.5,
    performanceTrend: 'improving',
    studyStreak: 7,
    weeklyActivityHours: 12.5,
    strongestSubject: 'Mathematics',
    weakestSubject: 'English',
    predictions: [tPrediction],
    recommendations: [tRecommendation],
  );

  setUp(() {
    mockRepository = MockAiRepository();
    bloc = AiInsightsBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is AiInsightsInitial', () {
    expect(bloc.state, isA<AiInsightsInitial>());
  });

  group('LoadStudentInsights', () {
    blocTest<AiInsightsBloc, AiInsightsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getStudentInsights(1),
        ).thenAnswer((_) async => const Right(tInsights));
        return bloc;
      },
      act: (b) => b.add(const LoadStudentInsights(userId: 1)),
      expect: () => [
        isA<AiInsightsLoading>(),
        isA<AiInsightsLoaded>()
            .having((s) => s.insights.overallPerformance, 'performance', 82.5)
            .having((s) => s.insights.predictions.length, 'predictions', 1)
            .having(
              (s) => s.insights.recommendations.length,
              'recommendations',
              1,
            ),
      ],
    );

    blocTest<AiInsightsBloc, AiInsightsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getStudentInsights(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Insights error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadStudentInsights(userId: 1)),
      expect: () => [
        isA<AiInsightsLoading>(),
        isA<AiInsightsError>().having(
          (s) => s.message,
          'message',
          'Insights error',
        ),
      ],
    );
  });

  group('StudentInsights entity', () {
    test('has correct performance trend', () {
      expect(tInsights.performanceTrend, 'improving');
    });

    test('has study streak', () {
      expect(tInsights.studyStreak, 7);
    });

    test('predictions contain risk levels', () {
      expect(tInsights.predictions.first.riskLevel, RiskLevel.low);
    });

    test('recommendations contain reason', () {
      expect(
        tInsights.recommendations.first.reason,
        RecommendationReason.sameCategory,
      );
    });
  });

  group('PerformancePrediction entity', () {
    test('completionLikelihood is between 0 and 1', () {
      expect(tPrediction.completionLikelihood, greaterThanOrEqualTo(0));
      expect(tPrediction.completionLikelihood, lessThanOrEqualTo(1));
    });

    test('has strengths and weaknesses', () {
      expect(tPrediction.strengths, isNotEmpty);
      expect(tPrediction.weaknesses, isNotEmpty);
    });
  });
}
