import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../domain/entities/calendar_event.dart' as cal;
import '../bloc/calendar_bloc.dart';

/// Calendar page showing monthly grid + event list with color coding.
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

/// Color helper for event types.
Color _colorForEventType(String type) {
  switch (type) {
    case 'course':
      return Colors.blue;
    case 'user':
      return Colors.green;
    case 'group':
      return Colors.orange;
    case 'site':
      return Colors.purple;
    case 'category':
      return Colors.teal;
    default:
      return Colors.grey;
  }
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
              GestureDetector(
                onTap: () {
                  // Go to today
                  final now = DateTime.now();
                  setState(() {
                    _focusedMonth = DateTime(now.year, now.month, 1);
                    _selectedDay = now;
                  });
                  context.read<CalendarBloc>().add(
                    ChangeMonth(month: _focusedMonth),
                  );
                },
                child: Column(
                  children: [
                    Text(
                      '${_focusedMonth.year} / ${_focusedMonth.month}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'calendar.today'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
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
        // Calendar grid
        _buildCalendarGrid(context),
        const Divider(),
        // Event type legend
        if (eventsForDay.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                Text(
                  '${eventsForDay.length} ${'calendar.events_count'.tr()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          )
        else
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
        const SizedBox(height: 4),
        // Events for selected day
        Expanded(
          child: eventsForDay.isEmpty
              ? Center(child: Text('calendar.no_events'.tr()))
              : ListView.builder(
                  itemCount: eventsForDay.length,
                  itemBuilder: (context, index) {
                    final e = eventsForDay[index];
                    final color = _colorForEventType(e.eventType);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showEventDetails(context, e),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(
                                  _iconForType(e.eventType),
                                  size: 20,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${e.startDateTime.hour}:${e.startDateTime.minute.toString().padLeft(2, '0')}'
                                      '${e.courseName != null ? ' • ${e.courseName}' : ''}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (e.timeDuration > 0)
                                Chip(
                                  label: Text(
                                    '${e.timeDuration ~/ 60} ${'common.minutes'.tr()}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showEventDetails(BuildContext context, cal.CalendarEvent event) {
    final color = _colorForEventType(event.eventType);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Event type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'calendar.event_types.${event.eventType}'.tr(),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                event.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Time
              _DetailRow(
                icon: Icons.access_time,
                label: 'calendar.start_time'.tr(),
                value:
                    '${event.startDateTime.day}/${event.startDateTime.month}/${event.startDateTime.year} '
                    '${event.startDateTime.hour}:${event.startDateTime.minute.toString().padLeft(2, '0')}',
              ),
              if (event.timeDuration > 0) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.timelapse,
                  label: 'meetings.duration'.tr(),
                  value: _formatDuration(event.timeDuration),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.access_time_filled,
                  label: 'calendar.end_time'.tr(),
                  value:
                      '${event.endDateTime.day}/${event.endDateTime.month}/${event.endDateTime.year} '
                      '${event.endDateTime.hour}:${event.endDateTime.minute.toString().padLeft(2, '0')}',
                ),
              ],
              if (event.courseName != null) ...[
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.school,
                  label: 'courses.title'.tr(),
                  value: event.courseName!,
                ),
              ],
              if (event.description != null &&
                  event.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'calendar.description'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  event.description!.replaceAll(RegExp(r'<[^>]*>'), ''),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours h ${minutes > 0 ? '$minutes min' : ''}';
    }
    return '$minutes min';
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
                final dayEvents = widget.eventsByDate[date] ?? [];
                final hasEvents = dayEvents.isNotEmpty;
                final isToday =
                    date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;
                final isSelected =
                    date.year == _selectedDay.year &&
                    date.month == _selectedDay.month &&
                    date.day == _selectedDay.day;

                // Get unique event type colors for this day
                final dotColors = hasEvents
                    ? dayEvents
                          .map((e) => _colorForEventType(e.eventType))
                          .toSet()
                          .take(3)
                          .toList()
                    : <Color>[];

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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dotColors
                                .map(
                                  (c) => Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 0.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : c,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                .toList(),
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
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
