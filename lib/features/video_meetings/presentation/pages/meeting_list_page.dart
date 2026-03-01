import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/meeting.dart';
import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';

/// Lists all BigBlueButton meetings for a course.
class MeetingListPage extends StatelessWidget {
  final int courseId;
  final String courseTitle;

  const MeetingListPage({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MeetingBloc(repository: sl())
            ..add(LoadMeetings(courseIds: [courseId])),
      child: Scaffold(
        appBar: AppBar(title: Text('meetings.title'.tr())),
        body: BlocBuilder<MeetingBloc, MeetingState>(
          builder: (context, state) {
            if (state is MeetingLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MeetingError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 12),
                    Text(state.message),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<MeetingBloc>().add(
                        LoadMeetings(courseIds: [courseId]),
                      ),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }
            if (state is MeetingsLoaded) {
              if (state.meetings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_off_outlined,
                        size: 64,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'meetings.no_meetings'.tr(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<MeetingBloc>().add(
                    LoadMeetings(courseIds: [courseId]),
                  );
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.meetings.length,
                  itemBuilder: (context, idx) {
                    final meeting = state.meetings[idx];
                    return _MeetingCard(
                      meeting: meeting,
                      onTap: () {
                        context.push(
                          '/meeting/${meeting.id}',
                          extra: {'meeting': meeting, 'courseId': courseId},
                        );
                      },
                    );
                  },
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTap;

  const _MeetingCard({required this.meeting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = meeting.isOpen
        ? Colors.green
        : meeting.isUpcoming
        ? Colors.orange
        : Colors.grey;
    final statusText = meeting.isOpen
        ? 'meetings.in_progress'.tr()
        : meeting.isUpcoming
        ? 'meetings.upcoming'.tr()
        : 'meetings.ended'.tr();
    final statusIcon = meeting.isOpen
        ? Icons.videocam
        : meeting.isUpcoming
        ? Icons.schedule
        : Icons.videocam_off;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              if (meeting.intro?.isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Text(
                  meeting.intro!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (meeting.openingDateTime != null ||
                  meeting.closingDateTime != null) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (meeting.openingDateTime != null) ...[
                      Icon(
                        Icons.play_circle_outline,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(meeting.openingDateTime!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (meeting.openingDateTime != null &&
                        meeting.closingDateTime != null)
                      const SizedBox(width: 16),
                    if (meeting.closingDateTime != null) ...[
                      Icon(
                        Icons.stop_circle_outlined,
                        size: 16,
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(meeting.closingDateTime!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
