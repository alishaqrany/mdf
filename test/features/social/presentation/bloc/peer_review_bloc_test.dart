import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/social/domain/entities/social_entities.dart';
import 'package:mdf_app/features/social/domain/repositories/social_repository.dart';
import 'package:mdf_app/features/social/presentation/bloc/peer_review_bloc.dart';

class MockSocialRepository extends Mock implements SocialRepository {}

void main() {
  late MockSocialRepository mockRepository;
  late PeerReviewBloc bloc;

  final tPendingReview = PeerReview(
    id: 1,
    workshopId: 10,
    workshopName: 'Essay Workshop',
    courseId: 101,
    courseName: 'English',
    submitterId: 2,
    submitterName: 'Sara',
    status: PeerReviewStatus.pending,
    submittedAt: DateTime(2024, 3, 10),
    submissionContent: 'My essay about...',
  );

  final tCompletedReview = PeerReview(
    id: 2,
    workshopId: 10,
    workshopName: 'Essay Workshop',
    courseId: 101,
    submitterId: 3,
    submitterName: 'Omar',
    reviewerId: 1,
    reviewerName: 'Ahmad',
    rating: 85.0,
    feedback: 'Well structured',
    status: PeerReviewStatus.completed,
    submittedAt: DateTime(2024, 3, 9),
    reviewedAt: DateTime(2024, 3, 11),
  );

  setUp(() {
    mockRepository = MockSocialRepository();
    bloc = PeerReviewBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is PeerReviewInitial', () {
    expect(bloc.state, isA<PeerReviewInitial>());
  });

  group('LoadPendingReviews', () {
    blocTest<PeerReviewBloc, PeerReviewState>(
      'emits [Loading, ListLoaded] with pending and completed reviews',
      build: () {
        when(
          () => mockRepository.getPendingReviews(1),
        ).thenAnswer((_) async => Right([tPendingReview]));
        when(
          () => mockRepository.getCompletedReviews(1),
        ).thenAnswer((_) async => Right([tCompletedReview]));
        return bloc;
      },
      act: (b) => b.add(const LoadPendingReviews(1)),
      expect: () => [
        isA<PeerReviewLoading>(),
        isA<PeerReviewListLoaded>()
            .having((s) => s.pending.length, 'pending', 1)
            .having((s) => s.completed.length, 'completed', 1),
      ],
    );

    blocTest<PeerReviewBloc, PeerReviewState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getPendingReviews(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Review error')),
        );
        when(
          () => mockRepository.getCompletedReviews(1),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (b) => b.add(const LoadPendingReviews(1)),
      expect: () => [isA<PeerReviewLoading>(), isA<PeerReviewError>()],
    );
  });

  group('LoadReviewDetail', () {
    blocTest<PeerReviewBloc, PeerReviewState>(
      'emits [Loading, DetailLoaded] on success',
      build: () {
        when(
          () => mockRepository.getReviewDetail(1),
        ).thenAnswer((_) async => Right(tPendingReview));
        return bloc;
      },
      act: (b) => b.add(const LoadReviewDetail(1)),
      expect: () => [
        isA<PeerReviewLoading>(),
        isA<PeerReviewDetailLoaded>().having((s) => s.review.id, 'id', 1),
      ],
    );
  });

  group('SubmitReview', () {
    blocTest<PeerReviewBloc, PeerReviewState>(
      'emits [Loading, Submitted] on success',
      build: () {
        when(
          () => mockRepository.submitReview(
            reviewId: any(named: 'reviewId'),
            rating: any(named: 'rating'),
            feedback: any(named: 'feedback'),
          ),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) => b.add(
        const SubmitReview(
          reviewId: 1,
          rating: 85.0,
          feedback: 'Well structured',
        ),
      ),
      expect: () => [isA<PeerReviewLoading>(), isA<PeerReviewSubmitted>()],
    );

    blocTest<PeerReviewBloc, PeerReviewState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.submitReview(
            reviewId: any(named: 'reviewId'),
            rating: any(named: 'rating'),
            feedback: any(named: 'feedback'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Submit failed')),
        );
        return bloc;
      },
      act: (b) => b.add(
        const SubmitReview(
          reviewId: 1,
          rating: 85.0,
          feedback: 'Well structured',
        ),
      ),
      expect: () => [isA<PeerReviewLoading>(), isA<PeerReviewError>()],
    );
  });

  group('PeerReview entity', () {
    test('pending review has no rating', () {
      expect(tPendingReview.rating, isNull);
      expect(tPendingReview.status, PeerReviewStatus.pending);
    });

    test('completed review has rating and feedback', () {
      expect(tCompletedReview.rating, 85.0);
      expect(tCompletedReview.feedback, isNotNull);
      expect(tCompletedReview.status, PeerReviewStatus.completed);
    });
  });
}
