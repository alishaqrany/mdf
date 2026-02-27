part of 'calendar_bloc.dart';

abstract class CalendarBlocEvent extends Equatable {
  const CalendarBlocEvent();
  @override
  List<Object?> get props => [];
}

class LoadCalendarEvents extends CalendarBlocEvent {
  final int? courseId;
  final int? timeStart;
  final int? timeEnd;
  final DateTime? selectedMonth;

  const LoadCalendarEvents({
    this.courseId,
    this.timeStart,
    this.timeEnd,
    this.selectedMonth,
  });

  @override
  List<Object?> get props => [courseId, timeStart, timeEnd, selectedMonth];
}

class LoadUpcomingEvents extends CalendarBlocEvent {
  const LoadUpcomingEvents();
}

class ChangeMonth extends CalendarBlocEvent {
  final DateTime month;
  const ChangeMonth({required this.month});
  @override
  List<Object?> get props => [month];
}
