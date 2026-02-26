import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/course_content.dart';
import '../../domain/repositories/course_content_repository.dart';
import '../datasources/course_content_remote_datasource.dart';

class CourseContentRepositoryImpl implements CourseContentRepository {
  final CourseContentRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CourseContentRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CourseSection>>> getCourseContents(
    int courseId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final sections = await remoteDataSource.getCourseContents(courseId);
      return Right(sections);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateActivityCompletion(
    int cmId,
    bool completed,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      await remoteDataSource.updateActivityCompletion(cmId, completed);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
