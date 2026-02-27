import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';

part 'quiz_event.dart';
part 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository repository;

  QuizBloc({required this.repository}) : super(QuizInitial()) {
    on<LoadQuizzes>(_onLoadQuizzes);
    on<LoadQuizAttempts>(_onLoadAttempts);
    on<StartQuizAttempt>(_onStartAttempt);
    on<LoadAttemptQuestions>(_onLoadQuestions);
    on<SaveQuizAnswer>(_onSaveAnswer);
    on<SubmitQuizAttempt>(_onSubmitAttempt);
    on<LoadAttemptReview>(_onLoadReview);
  }

  Future<void> _onLoadQuizzes(
    LoadQuizzes event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final result = await repository.getQuizzesByCourse(event.courseId);
    result.fold(
      (f) => emit(QuizError(message: f.message)),
      (quizzes) => emit(QuizzesLoaded(quizzes: quizzes)),
    );
  }

  Future<void> _onLoadAttempts(
    LoadQuizAttempts event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final result = await repository.getUserAttempts(event.quizId, event.userId);
    result.fold(
      (f) => emit(QuizError(message: f.message)),
      (attempts) => emit(QuizAttemptsLoaded(attempts: attempts)),
    );
  }

  Future<void> _onStartAttempt(
    StartQuizAttempt event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final result = await repository.startAttempt(event.quizId);
    result.fold(
      (f) => emit(QuizError(message: f.message)),
      (attempt) => emit(QuizAttemptStarted(attempt: attempt)),
    );
  }

  Future<void> _onLoadQuestions(
    LoadAttemptQuestions event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final result = await repository.getAttemptData(event.attemptId, event.page);
    result.fold(
      (f) => emit(QuizError(message: f.message)),
      (questions) => emit(QuizQuestionsLoaded(questions: questions)),
    );
  }

  Future<void> _onSaveAnswer(
    SaveQuizAnswer event,
    Emitter<QuizState> emit,
  ) async {
    await repository.saveAttempt(event.attemptId, event.data);
  }

  Future<void> _onSubmitAttempt(
    SubmitQuizAttempt event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final result = await repository.submitAttempt(event.attemptId);
    result.fold(
      (f) => emit(QuizError(message: f.message)),
      (_) => emit(QuizAttemptSubmitted()),
    );
  }

  Future<void> _onLoadReview(
    LoadAttemptReview event,
    Emitter<QuizState> emit,
  ) async {
    emit(QuizLoading());
    final result = await repository.getAttemptReview(event.attemptId);
    result.fold(
      (f) => emit(QuizError(message: f.message)),
      (questions) => emit(QuizReviewLoaded(questions: questions)),
    );
  }
}
