import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calendar_event.dart';

abstract class CalendarRepository {
  Future<Either<Failure, List<CalendarEvent>>> getCalendarEvents({
    int? courseId,
    int? timeStart,
    int? timeEnd,
  });

  Future<Either<Failure, List<CalendarEvent>>> getUpcomingEvents();
}
