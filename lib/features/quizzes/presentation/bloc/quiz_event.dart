part of 'quiz_bloc.dart';

abstract class QuizEvent extends Equatable {
  const QuizEvent();
  @override
  List<Object?> get props => [];
}

class LoadQuizzes extends QuizEvent {
  final int courseId;
  const LoadQuizzes({required this.courseId});
  @override
  List<Object?> get props => [courseId];
}

class LoadQuizAttempts extends QuizEvent {
  final int quizId;
  final int userId;
  const LoadQuizAttempts({required this.quizId, required this.userId});
  @override
  List<Object?> get props => [quizId, userId];
}

class StartQuizAttempt extends QuizEvent {
  final int quizId;
  const StartQuizAttempt({required this.quizId});
  @override
  List<Object?> get props => [quizId];
}

class LoadAttemptQuestions extends QuizEvent {
  final int attemptId;
  final int page;
  const LoadAttemptQuestions({required this.attemptId, this.page = 0});
  @override
  List<Object?> get props => [attemptId, page];
}

class SaveQuizAnswer extends QuizEvent {
  final int attemptId;
  final Map<String, String> data;
  const SaveQuizAnswer({required this.attemptId, required this.data});
  @override
  List<Object?> get props => [attemptId, data];
}

class SubmitQuizAttempt extends QuizEvent {
  final int attemptId;
  const SubmitQuizAttempt({required this.attemptId});
  @override
  List<Object?> get props => [attemptId];
}

class LoadAttemptReview extends QuizEvent {
  final int attemptId;
  const LoadAttemptReview({required this.attemptId});
  @override
  List<Object?> get props => [attemptId];
}
