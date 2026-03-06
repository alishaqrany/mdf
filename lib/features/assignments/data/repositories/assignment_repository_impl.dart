import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_remote_datasource.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AssignmentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Assignment>>> getAssignmentsByCourse(
    int courseId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final assignments = await remoteDataSource.getAssignmentsByCourse(
        courseId,
      );
      return Right(assignments);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Assignments'));
    }
  }

  @override
  Future<Either<Failure, List<AssignmentSubmission>>> getSubmissions(
    int assignmentId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final submissions = await remoteDataSource.getSubmissions(assignmentId);
      return Right(submissions);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Assignments'));
    }
  }

  @override
  Future<Either<Failure, List<AssignmentGrade>>> getGrades(
    int assignmentId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final grades = await remoteDataSource.getGrades(assignmentId);
      return Right(grades);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Assignments'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSubmission(
    int assignmentId,
    String? onlineText,
    int? fileItemId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.saveSubmission(
        assignmentId,
        onlineText,
        fileItemId,
      );
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Assignments'));
    }
  }

  @override
  Future<Either<Failure, void>> submitForGrading(int assignmentId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.submitForGrading(assignmentId);
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Assignments'));
    }
  }

  @override
  Future<Either<Failure, void>> saveGrade(
    int assignmentId,
    int userId,
    double grade,
    String? feedback,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.saveGrade(assignmentId, userId, grade, feedback);
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Assignments'));
    }
  }
}
