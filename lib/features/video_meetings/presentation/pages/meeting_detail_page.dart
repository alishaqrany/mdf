import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/colors.dart';
import '../../domain/entities/meeting.dart';
import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';

/// Detail page for a BBB meeting — shows info, join button, recordings.
class MeetingDetailPage extends StatelessWidget {
  final Meeting meeting;

  const MeetingDetailPage({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MeetingBloc(repository: sl())
        ..add(
          LoadMeetingInfo(meetingId: meeting.id, cmId: meeting.courseModule),
        ),
      child: Scaffold(
        appBar: AppBar(title: Text(meeting.name)),
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
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(state.message),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.read<MeetingBloc>().add(
                        LoadMeetingInfo(
                          meetingId: meeting.id,
                          cmId: meeting.courseModule,
                        ),
                      ),
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }
            if (state is MeetingInfoLoaded) {
              return _MeetingDetailContent(meeting: meeting, info: state.info);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _MeetingDetailContent extends StatelessWidget {
  final Meeting meeting;
  final MeetingInfo info;

  const _MeetingDetailContent({required this.meeting, required this.info});

  Future<void> _joinMeeting(BuildContext context) async {
    if (info.joinUrl == null || info.joinUrl!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('meetings.cannot_join'.tr())));
      return;
    }

    final uri = Uri.parse(info.joinUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('meetings.cannot_join'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = meeting.isOpen
        ? Colors.green
        : meeting.isUpcoming
        ? Colors.orange
        : Colors.grey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Meeting icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      meeting.isOpen ? Icons.videocam : Icons.videocam_off,
                      size: 48,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    meeting.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meeting.isOpen
                              ? 'meetings.in_progress'.tr()
                              : meeting.isUpcoming
                              ? 'meetings.upcoming'.tr()
                              : 'meetings.ended'.tr(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Participants indicator
                  if (info.isRunning &&
                      info.participantCount != null &&
                      info.participantCount! > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${info.participantCount} participants',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                  // Join button
                  if (info.canJoin || meeting.isOpen)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => _joinMeeting(context),
                        icon: const Icon(Icons.videocam),
                        label: Text('meetings.join'.tr()),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'meetings.details'.tr(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  if (meeting.intro?.isNotEmpty == true) ...[
                    Text(meeting.intro!),
                    const SizedBox(height: 12),
                  ],
                  if (meeting.openingDateTime != null)
                    _DetailRow(
                      icon: Icons.play_circle_outline,
                      label: 'meetings.starts_at'.tr(),
                      value: _formatDateTime(meeting.openingDateTime!),
                    ),
                  if (meeting.closingDateTime != null)
                    _DetailRow(
                      icon: Icons.stop_circle_outlined,
                      label: 'meetings.ends_at'.tr(),
                      value: _formatDateTime(meeting.closingDateTime!),
                    ),
                  if (meeting.openingDateTime != null &&
                      meeting.closingDateTime != null)
                    _DetailRow(
                      icon: Icons.timer,
                      label: 'meetings.duration'.tr(),
                      value: _formatDuration(
                        meeting.closingDateTime!.difference(
                          meeting.openingDateTime!,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Recordings Card
          if (info.recordings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'meetings.recordings'.tr(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    ...info.recordings.map(
                      (rec) => ListTile(
                        leading: const Icon(
                          Icons.play_circle_filled,
                          color: AppColors.primary,
                        ),
                        title: Text(rec.name ?? 'meetings.recording'.tr()),
                        subtitle: rec.startDateTime != null
                            ? Text(_formatDateTime(rec.startDateTime!))
                            : null,
                        trailing: const Icon(Icons.open_in_new),
                        contentPadding: EdgeInsets.zero,
                        onTap: () async {
                          if (rec.playbackUrl != null) {
                            final uri = Uri.parse(rec.playbackUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondaryLight),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
