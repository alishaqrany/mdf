import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../../course_visibility/data/datasources/course_visibility_remote_datasource.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/courses_repository.dart';
import '../datasources/courses_remote_datasource.dart';
import '../models/course_model.dart';

class CoursesRepositoryImpl implements CoursesRepository {
  final CoursesRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final CourseVisibilityRemoteDataSource? visibilityDataSource;

  /// Cached set of hidden course IDs for current session.
  Set<int>? _hiddenCourseIds;

  CoursesRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    this.visibilityDataSource,
  });

  /// Fetch hidden course IDs from MDF plugin (silently fails if plugin unavailable).
  Future<Set<int>> _getHiddenCourseIds() async {
    if (_hiddenCourseIds != null) return _hiddenCourseIds!;
    try {
      if (visibilityDataSource != null) {
        final ids = await visibilityDataSource!.getHiddenCourses();
        _hiddenCourseIds = ids.toSet();
        return _hiddenCourseIds!;
      }
    } catch (_) {
      // Plugin not available or error — no filtering.
    }
    _hiddenCourseIds = {};
    return _hiddenCourseIds!;
  }

  /// Filter out hidden courses. Safety: if hidden set covers ALL courses,
  /// something is wrong — don't filter.
  List<Course> _filterHidden(List<Course> courses, Set<int> hidden) {
    if (hidden.isEmpty) return courses;
    final filtered = courses.where((c) => !hidden.contains(c.id)).toList();
    // Sanity: if filtering removes everything, return the original list.
    if (filtered.isEmpty && courses.isNotEmpty) return courses;
    return filtered;
  }

  @override
  Future<Either<Failure, List<Course>>> getEnrolledCourses(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final courses = await remoteDataSource.getEnrolledCourses(userId);
        // Cache the result
        CacheManager.put(
          boxName: CacheConfig.coursesBox,
          key: 'enrolled_$userId',
          data: courses.map((c) => c.toJson()).toList(),
        );
        // Filter hidden courses (wrapped in try-catch so it never blocks course display)
        Set<int> hidden = {};
        try {
          hidden = await _getHiddenCourseIds();
        } catch (_) {
          // If hidden courses fetch fails, show all courses.
        }
        return Right(_filterHidden(courses, hidden));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
    // Offline: try cache
    final cached = CacheManager.getList<Course>(
      boxName: CacheConfig.coursesBox,
      key: 'enrolled_$userId',
      ttl: CacheConfig.longTTL,
      fromJson: (json) => CourseModel.fromEnrolledCourse(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }

  @override
  Future<Either<Failure, List<Course>>> getRecentCourses(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final courses = await remoteDataSource.getRecentCourses(userId);
        CacheManager.put(
          boxName: CacheConfig.coursesBox,
          key: 'recent_$userId',
          data: courses.map((c) => c.toJson()).toList(),
        );
        // Filter hidden courses
        final hidden = await _getHiddenCourseIds();
        return Right(_filterHidden(courses, hidden));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
    final cached = CacheManager.getList<Course>(
      boxName: CacheConfig.coursesBox,
      key: 'recent_$userId',
      ttl: CacheConfig.defaultTTL,
      fromJson: (json) => CourseModel.fromEnrolledCourse(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }

  @override
  Future<Either<Failure, List<Course>>> searchCourses(String query) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final courses = await remoteDataSource.searchCourses(query);
      return Right(courses);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Course>>> getAllCourses() async {
    if (await networkInfo.isConnected) {
      try {
        final courses = await remoteDataSource.getAllCourses();
        CacheManager.put(
          boxName: CacheConfig.coursesBox,
          key: 'all_courses',
          data: courses.map((c) => c.toJson()).toList(),
        );
        return Right(courses);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
    final cached = CacheManager.getList<Course>(
      boxName: CacheConfig.coursesBox,
      key: 'all_courses',
      ttl: CacheConfig.longTTL,
      fromJson: (json) => CourseModel.fromEnrolledCourse(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }

  @override
  Future<Either<Failure, List<CourseCategory>>> getCategories() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final categories = await remoteDataSource.getCategories();
      return Right(categories);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Course>> getCourseById(int courseId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final course = await remoteDataSource.getCourseById(courseId);
      return Right(course);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
