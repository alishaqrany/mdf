import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/calendar/domain/entities/calendar_event.dart';
import 'package:mdf_app/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:mdf_app/features/calendar/presentation/bloc/calendar_bloc.dart';

class MockCalendarRepository extends Mock implements CalendarRepository {}

void main() {
  late MockCalendarRepository mockRepository;
  late CalendarBloc bloc;

  final tEvent = CalendarEvent(
    id: 1,
    name: 'Assignment Due',
    eventType: 'due',
    timeStart: DateTime(2024, 3, 15, 14, 0).millisecondsSinceEpoch ~/ 1000,
    timeDuration: 3600,
    courseId: 101,
    courseName: 'Mathematics',
    description: 'Submit your homework.',
  );

  final tEvents = [tEvent];

  setUp(() {
    mockRepository = MockCalendarRepository();
    bloc = CalendarBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is CalendarInitial', () {
    expect(bloc.state, isA<CalendarInitial>());
  });

  group('LoadCalendarEvents', () {
    blocTest<CalendarBloc, CalendarState>(
      'emits [Loading, EventsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getCalendarEvents(
            courseId: any(named: 'courseId'),
            timeStart: any(named: 'timeStart'),
            timeEnd: any(named: 'timeEnd'),
          ),
        ).thenAnswer((_) async => Right(tEvents));
        return bloc;
      },
      act: (b) => b.add(const LoadCalendarEvents()),
      expect: () => [
        isA<CalendarLoading>(),
        isA<CalendarEventsLoaded>().having(
          (s) => s.events.length,
          'event count',
          1,
        ),
      ],
    );

    blocTest<CalendarBloc, CalendarState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(
          () => mockRepository.getCalendarEvents(
            courseId: any(named: 'courseId'),
            timeStart: any(named: 'timeStart'),
            timeEnd: any(named: 'timeEnd'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Calendar error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadCalendarEvents()),
      expect: () => [
        isA<CalendarLoading>(),
        isA<CalendarError>().having(
          (s) => s.message,
          'message',
          'Calendar error',
        ),
      ],
    );
  });

  group('LoadUpcomingEvents', () {
    blocTest<CalendarBloc, CalendarState>(
      'emits [Loading, EventsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getUpcomingEvents(),
        ).thenAnswer((_) async => Right(tEvents));
        return bloc;
      },
      act: (b) => b.add(const LoadUpcomingEvents()),
      expect: () => [isA<CalendarLoading>(), isA<CalendarEventsLoaded>()],
    );

    blocTest<CalendarBloc, CalendarState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getUpcomingEvents()).thenAnswer(
          (_) async => const Left(NetworkFailure(message: 'No connection')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadUpcomingEvents()),
      expect: () => [isA<CalendarLoading>(), isA<CalendarError>()],
    );
  });

  group('ChangeMonth', () {
    final targetMonth = DateTime(2024, 4, 1);

    blocTest<CalendarBloc, CalendarState>(
      'loads events for the given month',
      build: () {
        when(
          () => mockRepository.getCalendarEvents(
            courseId: any(named: 'courseId'),
            timeStart: any(named: 'timeStart'),
            timeEnd: any(named: 'timeEnd'),
          ),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (b) => b.add(ChangeMonth(month: targetMonth)),
      expect: () => [
        isA<CalendarLoading>(),
        isA<CalendarEventsLoaded>().having(
          (s) => s.selectedMonth.month,
          'month',
          4,
        ),
      ],
    );
  });

  group('CalendarEvent entity', () {
    test('startDateTime converts from epoch', () {
      expect(tEvent.startDateTime, isA<DateTime>());
    });

    test('endDateTime = startDateTime + duration', () {
      final diff = tEvent.endDateTime
          .difference(tEvent.startDateTime)
          .inSeconds;
      expect(diff, tEvent.timeDuration);
    });

    test('isAllDay is true when duration >= 86400', () {
      const allDay = CalendarEvent(
        id: 2,
        name: 'Holiday',
        eventType: 'site',
        timeStart: 1700000000,
        timeDuration: 86400,
      );
      expect(allDay.isAllDay, isTrue);
    });
  });
}
