part of 'quiz_bloc.dart';

abstract class QuizState extends Equatable {
  const QuizState();
  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {}

class QuizLoading extends QuizState {}

class QuizzesLoaded extends QuizState {
  final List<Quiz> quizzes;
  const QuizzesLoaded({required this.quizzes});
  @override
  List<Object?> get props => [quizzes];
}

class QuizAttemptsLoaded extends QuizState {
  final List<QuizAttempt> attempts;
  const QuizAttemptsLoaded({required this.attempts});
  @override
  List<Object?> get props => [attempts];
}

class QuizAttemptStarted extends QuizState {
  final QuizAttempt attempt;
  const QuizAttemptStarted({required this.attempt});
  @override
  List<Object?> get props => [attempt];
}

class QuizQuestionsLoaded extends QuizState {
  final List<QuizQuestion> questions;
  const QuizQuestionsLoaded({required this.questions});
  @override
  List<Object?> get props => [questions];
}

class QuizAttemptSubmitted extends QuizState {}

class QuizReviewLoaded extends QuizState {
  final List<QuizQuestion> questions;
  const QuizReviewLoaded({required this.questions});
  @override
  List<Object?> get props => [questions];
}

class QuizError extends QuizState {
  final String message;
  const QuizError({required this.message});
  @override
  List<Object?> get props => [message];
}
