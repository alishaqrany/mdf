import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/cache_manager.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_datasource.dart';
import '../models/calendar_event_model.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CalendarRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CalendarEvent>>> getCalendarEvents({
    int? courseId,
    int? timeStart,
    int? timeEnd,
  }) async {
    final cacheKey =
        'events_${courseId ?? 'all'}_${timeStart ?? 0}_${timeEnd ?? 0}';
    if (await networkInfo.isConnected) {
      try {
        final events = await remoteDataSource.getCalendarEvents(
          courseId: courseId,
          timeStart: timeStart,
          timeEnd: timeEnd,
        );
        CacheManager.put(
          boxName: CacheConfig.calendarBox,
          key: cacheKey,
          data: events.map((e) => e.toJson()).toList(),
        );
        return Right(events);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
    final cached = CacheManager.getList<CalendarEvent>(
      boxName: CacheConfig.calendarBox,
      key: cacheKey,
      ttl: CacheConfig.shortTTL,
      fromJson: (json) => CalendarEventModel.fromJson(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getUpcomingEvents() async {
    if (await networkInfo.isConnected) {
      try {
        final events = await remoteDataSource.getUpcomingEvents();
        CacheManager.put(
          boxName: CacheConfig.calendarBox,
          key: 'upcoming',
          data: events.map((e) => e.toJson()).toList(),
        );
        return Right(events);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(UnexpectedFailure(message: e.toString()));
      }
    }
    final cached = CacheManager.getList<CalendarEvent>(
      boxName: CacheConfig.calendarBox,
      key: 'upcoming',
      ttl: CacheConfig.shortTTL,
      fromJson: (json) => CalendarEventModel.fromJson(json),
    );
    if (cached != null) return Right(cached);
    return const Left(NetworkFailure());
  }
}
