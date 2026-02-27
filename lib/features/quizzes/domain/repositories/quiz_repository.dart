import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz.dart';

abstract class QuizRepository {
  Future<Either<Failure, List<Quiz>>> getQuizzesByCourse(int courseId);
  Future<Either<Failure, List<QuizAttempt>>> getUserAttempts(
    int quizId,
    int userId,
  );
  Future<Either<Failure, QuizAttempt>> startAttempt(int quizId);
  Future<Either<Failure, List<QuizQuestion>>> getAttemptData(
    int attemptId,
    int page,
  );
  Future<Either<Failure, void>> saveAttempt(
    int attemptId,
    Map<String, String> data,
  );
  Future<Either<Failure, void>> submitAttempt(int attemptId);
  Future<Either<Failure, List<QuizQuestion>>> getAttemptReview(int attemptId);
}
