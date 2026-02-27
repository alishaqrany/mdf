import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/calendar_event.dart' as cal;
import '../bloc/calendar_bloc.dart';

/// Calendar page showing monthly grid + event list.
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CalendarBloc(repository: sl())..add(const LoadUpcomingEvents()),
      child: Scaffold(
        appBar: AppBar(title: Text('calendar.title'.tr())),
        body: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            if (state is CalendarLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CalendarError) {
              return Center(child: Text(state.message));
            }
            if (state is CalendarEventsLoaded) {
              return _CalendarView(
                events: state.events,
                selectedMonth: state.selectedMonth,
                eventsByDate: state.eventsByDate,
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _CalendarView extends StatefulWidget {
  final List<cal.CalendarEvent> events;
  final DateTime selectedMonth;
  final Map<DateTime, List<cal.CalendarEvent>> eventsByDate;

  const _CalendarView({
    required this.events,
    required this.selectedMonth,
    required this.eventsByDate,
  });

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _selectedDay;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _focusedMonth = widget.selectedMonth;
  }

  @override
  Widget build(BuildContext context) {
    final eventsForDay =
        widget.eventsByDate[DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        )] ??
        [];

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prev = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                    1,
                  );
                  setState(() => _focusedMonth = prev);
                  context.read<CalendarBloc>().add(ChangeMonth(month: prev));
                },
              ),
              Text(
                '${_focusedMonth.year} / ${_focusedMonth.month}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final next = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                    1,
                  );
                  setState(() => _focusedMonth = next);
                  context.read<CalendarBloc>().add(ChangeMonth(month: next));
                },
              ),
            ],
          ),
        ),
        // Simple calendar grid
        _buildCalendarGrid(context),
        const Divider(),
        // Events for selected day
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),
        Expanded(
          child: eventsForDay.isEmpty
              ? Center(child: Text('calendar.no_events'.tr()))
              : ListView.builder(
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) {
                    final e = eventsForDay[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(_iconForType(e.eventType), size: 20),
                      ),
                      title: Text(e.name),
                      subtitle: Text(
                        '${e.startDateTime.hour}:${e.startDateTime.minute.toString().padLeft(2, '0')}'
                        '${e.courseName != null ? ' • ${e.courseName}' : ''}',
                      ),
                      trailing: e.timeDuration > 0
                          ? Text('${e.timeDuration ~/ 60} min')
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7; // 0=Sun

    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final today = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayLabels
                .map(
                  (d) => SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        d,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...List.generate(((startWeekday + daysInMonth) / 7).ceil(), (week) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dow) {
                final dayIndex = week * 7 + dow - startWeekday + 1;
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const SizedBox(width: 40, height: 40);
                }
                final date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  dayIndex,
                );
                final hasEvents = widget.eventsByDate.containsKey(date);
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected =
                    date.year == _selectedDay.year &&
                    date.month == _selectedDay.month &&
                    date.day == _selectedDay.day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = date),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      border: isToday
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayIndex',
                          style: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isToday ? FontWeight.bold : null,
                            fontSize: 13,
                          ),
                        ),
                        if (hasEvents)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'course':
        return Icons.school;
      case 'user':
        return Icons.person;
      case 'group':
        return Icons.group;
      case 'site':
        return Icons.public;
      default:
        return Icons.event;
    }
  }
}
