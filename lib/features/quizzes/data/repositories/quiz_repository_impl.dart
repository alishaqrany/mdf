import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../datasources/quiz_remote_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  QuizRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Quiz>>> getQuizzesByCourse(int courseId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final quizzes = await remoteDataSource.getQuizzesByCourse(courseId);
      return Right(quizzes);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizAttempt>>> getUserAttempts(
    int quizId,
    int userId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final attempts = await remoteDataSource.getUserAttempts(quizId, userId);
      return Right(attempts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuizAttempt>> startAttempt(int quizId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final attempt = await remoteDataSource.startAttempt(quizId);
      return Right(attempt);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizQuestion>>> getAttemptData(
    int attemptId,
    int page,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final questions = await remoteDataSource.getAttemptData(attemptId, page);
      return Right(questions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAttempt(
    int attemptId,
    Map<String, String> data,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.saveAttempt(attemptId, data);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitAttempt(int attemptId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.submitAttempt(attemptId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuizQuestion>>> getAttemptReview(
    int attemptId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final questions = await remoteDataSource.getAttemptReview(attemptId);
      return Right(questions);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
