import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/social_entities.dart';
import '../../domain/repositories/social_repository.dart';

// ─── Events ───
abstract class PeerReviewEvent extends Equatable {
  const PeerReviewEvent();
  @override
  List<Object?> get props => [];
}

class LoadPendingReviews extends PeerReviewEvent {
  final int userId;
  const LoadPendingReviews(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadCompletedReviews extends PeerReviewEvent {
  final int userId;
  const LoadCompletedReviews(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadReviewDetail extends PeerReviewEvent {
  final int reviewId;
  const LoadReviewDetail(this.reviewId);
  @override
  List<Object?> get props => [reviewId];
}

class SubmitReview extends PeerReviewEvent {
  final int reviewId;
  final double rating;
  final String feedback;

  const SubmitReview({
    required this.reviewId,
    required this.rating,
    required this.feedback,
  });

  @override
  List<Object?> get props => [reviewId, rating];
}

// ─── States ───
abstract class PeerReviewState extends Equatable {
  const PeerReviewState();
  @override
  List<Object?> get props => [];
}

class PeerReviewInitial extends PeerReviewState {}

class PeerReviewLoading extends PeerReviewState {}

class PeerReviewListLoaded extends PeerReviewState {
  final List<PeerReview> pending;
  final List<PeerReview> completed;
  const PeerReviewListLoaded({
    this.pending = const [],
    this.completed = const [],
  });
  @override
  List<Object?> get props => [pending, completed];
}

class PeerReviewDetailLoaded extends PeerReviewState {
  final PeerReview review;
  const PeerReviewDetailLoaded(this.review);
  @override
  List<Object?> get props => [review];
}

class PeerReviewSubmitted extends PeerReviewState {}

class PeerReviewError extends PeerReviewState {
  final String message;
  const PeerReviewError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class PeerReviewBloc extends Bloc<PeerReviewEvent, PeerReviewState> {
  final SocialRepository repository;

  PeerReviewBloc({required this.repository}) : super(PeerReviewInitial()) {
    on<LoadPendingReviews>(_onLoadPending);
    on<LoadCompletedReviews>(_onLoadCompleted);
    on<LoadReviewDetail>(_onLoadDetail);
    on<SubmitReview>(_onSubmit);
  }

  Future<void> _onLoadPending(
    LoadPendingReviews event,
    Emitter<PeerReviewState> emit,
  ) async {
    emit(PeerReviewLoading());
    final pendingResult = await repository.getPendingReviews(event.userId);
    final completedResult = await repository.getCompletedReviews(event.userId);
    pendingResult.fold((f) => emit(PeerReviewError(f.message)), (pending) {
      completedResult.fold(
        (f) => emit(PeerReviewListLoaded(pending: pending)),
        (completed) =>
            emit(PeerReviewListLoaded(pending: pending, completed: completed)),
      );
    });
  }

  Future<void> _onLoadCompleted(
    LoadCompletedReviews event,
    Emitter<PeerReviewState> emit,
  ) async {
    emit(PeerReviewLoading());
    final result = await repository.getCompletedReviews(event.userId);
    result.fold(
      (f) => emit(PeerReviewError(f.message)),
      (completed) => emit(PeerReviewListLoaded(completed: completed)),
    );
  }

  Future<void> _onLoadDetail(
    LoadReviewDetail event,
    Emitter<PeerReviewState> emit,
  ) async {
    emit(PeerReviewLoading());
    final result = await repository.getReviewDetail(event.reviewId);
    result.fold(
      (f) => emit(PeerReviewError(f.message)),
      (review) => emit(PeerReviewDetailLoaded(review)),
    );
  }

  Future<void> _onSubmit(
    SubmitReview event,
    Emitter<PeerReviewState> emit,
  ) async {
    emit(PeerReviewLoading());
    final result = await repository.submitReview(
      reviewId: event.reviewId,
      rating: event.rating,
      feedback: event.feedback,
    );
    result.fold(
      (f) => emit(PeerReviewError(f.message)),
      (_) => emit(PeerReviewSubmitted()),
    );
  }
}
