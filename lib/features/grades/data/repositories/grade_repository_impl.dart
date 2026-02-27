import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import '../datasources/grade_remote_datasource.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GradeRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<GradeItem>>> getGradeItems(
    int courseId,
    int userId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final items = await remoteDataSource.getGradeItems(courseId, userId);
      return Right(items);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CourseGrade>>> getCourseGrades(int userId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final grades = await remoteDataSource.getCourseGrades(userId);
      return Right(grades);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
