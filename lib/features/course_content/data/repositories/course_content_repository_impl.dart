import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../domain/entities/course_content.dart';
import '../../domain/repositories/course_content_repository.dart';
import '../datasources/course_content_remote_datasource.dart';
import '../models/course_content_model.dart';

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
    if (await networkInfo.isConnected) {
      try {
        final sections = await remoteDataSource.getCourseContents(courseId);
        CacheManager.put(
          boxName: CacheConfig.courseContentBox,
          key: 'content_$courseId',
          data: sections.map((s) => s.toJson()).toList(),
        );
        return Right(sections);
      } on ServerException catch (e) {
        final lowerMessage = e.message.toLowerCase();
        if (lowerMessage.contains('accessexception') ||
            lowerMessage.contains('nopermissions')) {
          return const Right(<CourseSection>[]);
        }
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
    final cached = CacheManager.getList<CourseSection>(
      boxName: CacheConfig.courseContentBox,
      key: 'content_$courseId',
      ttl: CacheConfig.defaultTTL,
      fromJson: (json) => CourseSectionModel.fromJson(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
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
