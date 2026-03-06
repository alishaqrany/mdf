import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../domain/entities/grade.dart';
import '../../domain/repositories/grade_repository.dart';
import '../datasources/grade_remote_datasource.dart';
import '../models/grade_model.dart';

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
    if (await networkInfo.isConnected) {
      try {
        final items = await remoteDataSource.getGradeItems(courseId, userId);
        CacheManager.put(
          boxName: CacheConfig.gradesBox,
          key: 'items_${courseId}_$userId',
          data: items.map((i) => i.toJson()).toList(),
        );
        return Right(items);
      } catch (e) {
        return Left(MdfErrorHandler.handleException(e, featureName: 'Grades'));
      }
    }
    final cached = CacheManager.getList<GradeItem>(
      boxName: CacheConfig.gradesBox,
      key: 'items_${courseId}_$userId',
      ttl: CacheConfig.defaultTTL,
      fromJson: (json) => GradeItemModel.fromJson(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }

  @override
  Future<Either<Failure, List<CourseGrade>>> getCourseGrades(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final grades = await remoteDataSource.getCourseGrades(userId);
        CacheManager.put(
          boxName: CacheConfig.gradesBox,
          key: 'courses_$userId',
          data: grades.map((g) => g.toJson()).toList(),
        );
        return Right(grades);
      } catch (e) {
        return Left(MdfErrorHandler.handleException(e, featureName: 'Grades'));
      }
    }
    final cached = CacheManager.getList<CourseGrade>(
      boxName: CacheConfig.gradesBox,
      key: 'courses_$userId',
      ttl: CacheConfig.defaultTTL,
      fromJson: (json) => CourseGradeModel.fromJson(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }
}
