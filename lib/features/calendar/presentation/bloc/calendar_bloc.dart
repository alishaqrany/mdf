import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';

part 'calendar_event_bloc.dart';
part 'calendar_state.dart';

class CalendarBloc extends Bloc<CalendarBlocEvent, CalendarState> {
  final CalendarRepository repository;

  CalendarBloc({required this.repository}) : super(CalendarInitial()) {
    on<LoadCalendarEvents>(_onLoadEvents);
    on<LoadUpcomingEvents>(_onLoadUpcoming);
    on<ChangeMonth>(_onChangeMonth);
  }

  Future<void> _onLoadEvents(
    LoadCalendarEvents event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    final result = await repository.getCalendarEvents(
      courseId: event.courseId,
      timeStart: event.timeStart,
      timeEnd: event.timeEnd,
    );
    result.fold(
      (f) => emit(CalendarError(message: f.message)),
      (events) => emit(
        CalendarEventsLoaded(
          events: events,
          selectedMonth: event.selectedMonth ?? DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onLoadUpcoming(
    LoadUpcomingEvents event,
    Emitter<CalendarState> emit,
  ) async {
    emit(CalendarLoading());
    final result = await repository.getUpcomingEvents();
    result.fold(
      (f) => emit(CalendarError(message: f.message)),
      (events) => emit(
        CalendarEventsLoaded(events: events, selectedMonth: DateTime.now()),
      ),
    );
  }

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<CalendarState> emit,
  ) async {
    final start = DateTime(event.month.year, event.month.month, 1);
    final end = DateTime(event.month.year, event.month.month + 1, 0, 23, 59);

    emit(CalendarLoading());
    final result = await repository.getCalendarEvents(
      timeStart: start.millisecondsSinceEpoch ~/ 1000,
      timeEnd: end.millisecondsSinceEpoch ~/ 1000,
    );
    result.fold(
      (f) => emit(CalendarError(message: f.message)),
      (events) => emit(
        CalendarEventsLoaded(events: events, selectedMonth: event.month),
      ),
    );
  }
}
