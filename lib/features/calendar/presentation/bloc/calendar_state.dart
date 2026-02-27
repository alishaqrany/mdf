part of 'calendar_bloc.dart';

abstract class CalendarState extends Equatable {
  const CalendarState();
  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {}

class CalendarLoading extends CalendarState {}

class CalendarEventsLoaded extends CalendarState {
  final List<CalendarEvent> events;
  final DateTime selectedMonth;

  const CalendarEventsLoaded({
    required this.events,
    required this.selectedMonth,
  });

  /// Group events by date for the calendar grid.
  Map<DateTime, List<CalendarEvent>> get eventsByDate {
    final map = <DateTime, List<CalendarEvent>>{};
    for (final e in events) {
      final date = DateTime(
        e.startDateTime.year,
        e.startDateTime.month,
        e.startDateTime.day,
      );
      map.putIfAbsent(date, () => []).add(e);
    }
    return map;
  }

  @override
  List<Object?> get props => [events, selectedMonth];
}

class CalendarError extends CalendarState {
  final String message;
  const CalendarError({required this.message});
  @override
  List<Object?> get props => [message];
}
