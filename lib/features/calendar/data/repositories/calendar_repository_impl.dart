import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_datasource.dart';

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
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final events = await remoteDataSource.getCalendarEvents(
        courseId: courseId,
        timeStart: timeStart,
        timeEnd: timeEnd,
      );
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getUpcomingEvents() async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final events = await remoteDataSource.getUpcomingEvents();
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
