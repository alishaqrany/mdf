import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/social_entities.dart';
import '../bloc/collaborative_bloc.dart';

class CollaborativeSessionPage extends StatelessWidget {
  final int groupId;
  final String groupName;

  const CollaborativeSessionPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<CollaborativeBloc>()..add(LoadGroupSessions(groupId)),
      child: _SessionsView(groupId: groupId, groupName: groupName),
    );
  }
}

class _SessionsView extends StatelessWidget {
  final int groupId;
  final String groupName;

  const _SessionsView({required this.groupId, required this.groupName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(groupName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSession(context),
        icon: const Icon(Icons.add_rounded),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            tr('social.new_session'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: BlocConsumer<CollaborativeBloc, CollaborativeState>(
        listener: (context, state) {
          if (state is CollaborativeActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.action)),
            );
            context.read<CollaborativeBloc>().add(
              LoadGroupSessions(groupId),
            );
          }
          if (state is CollaborativeSessionCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('social.session_created'))),
            );
            context.read<CollaborativeBloc>().add(
              LoadGroupSessions(groupId),
            );
          }
        },
        builder: (context, state) {
          if (state is CollaborativeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CollaborativeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context
                        .read<CollaborativeBloc>()
                        .add(LoadGroupSessions(groupId)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is CollaborativeSessionsLoaded) {
            if (state.sessions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.groups_3_outlined,
                      size: 80,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('social.no_sessions'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            final active = state.sessions
                .where((s) => s.status == SessionStatus.active)
                .toList();
            final scheduled = state.sessions
                .where((s) => s.status == SessionStatus.scheduled)
                .toList();
            final ended = state.sessions
                .where((s) =>
                    s.status == SessionStatus.ended ||
                    s.status == SessionStatus.cancelled)
                .toList();

            return RefreshIndicator(
              onRefresh: () async => context
                  .read<CollaborativeBloc>()
                  .add(LoadGroupSessions(groupId)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  if (active.isNotEmpty) ...[
                    _SectionHeader(
                      title: tr('social.active_sessions'),
                      icon: Icons.play_circle_rounded,
                      color: AppColors.success,
                    ),
                    ...active.asMap().entries.map(
                      (e) => FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: e.key * 80),
                        child: _SessionCard(
                          session: e.value,
                          onTap: () =>
                              _showSessionDetail(context, e.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (scheduled.isNotEmpty) ...[
                    _SectionHeader(
                      title: tr('social.scheduled_sessions'),
                      icon: Icons.schedule_rounded,
                      color: AppColors.info,
                    ),
                    ...scheduled.asMap().entries.map(
                      (e) => FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: e.key * 80),
                        child: _SessionCard(
                          session: e.value,
                          onTap: () =>
                              _showSessionDetail(context, e.value),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (ended.isNotEmpty) ...[
                    _SectionHeader(
                      title: tr('social.past_sessions'),
                      icon: Icons.history_rounded,
                      color: AppColors.textTertiaryLight,
                    ),
                    ...ended.asMap().entries.map(
                      (e) => FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: e.key * 80),
                        child: _SessionCard(
                          session: e.value,
                          onTap: () =>
                              _showSessionDetail(context, e.value),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _showCreateSession(BuildContext context) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime startTime = DateTime.now().add(const Duration(hours: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('social.new_session'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: tr('social.session_title'),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: tr('social.description'),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(tr('social.start_time')),
                subtitle: Text(
                  DateFormat.yMd().add_jm().format(startTime),
                ),
                leading: const Icon(Icons.access_time_rounded),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.divider),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: startTime,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null && ctx.mounted) {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(startTime),
                    );
                    if (time != null) {
                      setState(() {
                        startTime = DateTime(
                          date.year, date.month, date.day,
                          time.hour, time.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (titleCtrl.text.trim().isNotEmpty) {
                    context.read<CollaborativeBloc>().add(
                      CreateSession(
                        title: titleCtrl.text.trim(),
                        groupId: groupId,
                        startTime: startTime,
                        description: descCtrl.text.trim().isEmpty
                            ? null
                            : descCtrl.text.trim(),
                      ),
                    );
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(tr('social.create')),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetail(BuildContext context, CollaborativeSession session) {
    final theme = Theme.of(context);
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ListView(
            controller: scrollCtrl,
            children: [
              // Title & Status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      session.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _sessionStatusColor(session.status)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      session.status.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _sessionStatusColor(session.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Time info
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMd().add_jm().format(session.startTime),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.endTime != null) ...[
                    const Text(' — '),
                    Text(
                      DateFormat.jm().format(session.endTime!),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${session.participantCount} ${tr('social.participants')}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Divider(height: 24),

              // Action buttons
              if (session.status == SessionStatus.scheduled ||
                  session.status == SessionStatus.active)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<CollaborativeBloc>().add(
                            JoinSession(session.id),
                          );
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.login_rounded),
                        label: Text(tr('social.join_session')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<CollaborativeBloc>().add(
                            EndSession(session.id),
                          );
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.stop_rounded),
                        label: Text(tr('social.end_session')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),

              // Session notes
              if (session.sharedNotes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  tr('social.session_notes'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...session.sharedNotes.map(
                  (note) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(note.content),
                      subtitle: Text(
                        '${note.authorName} — ${DateFormat.jm().format(note.createdAt)}',
                      ),
                      leading: const Icon(Icons.note_rounded),
                    ),
                  ),
                ),
              ],

              // Add note
              if (session.status == SessionStatus.active) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: noteCtrl,
                        decoration: InputDecoration(
                          hintText: tr('social.add_note'),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () {
                        if (noteCtrl.text.trim().isNotEmpty) {
                          context.read<CollaborativeBloc>().add(
                            AddSessionNoteEvent(
                              sessionId: session.id,
                              content: noteCtrl.text.trim(),
                            ),
                          );
                          noteCtrl.clear();
                        }
                      },
                      icon: const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _sessionStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return AppColors.info;
      case SessionStatus.active:
        return AppColors.success;
      case SessionStatus.ended:
        return AppColors.textTertiaryLight;
      case SessionStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CollaborativeSession session;
  final VoidCallback onTap;

  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(session.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondaryLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat.yMd()
                              .add_jm()
                              .format(session.startTime),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      session.status.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${session.participantCount}',
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return AppColors.info;
      case SessionStatus.active:
        return AppColors.success;
      case SessionStatus.ended:
        return AppColors.textTertiaryLight;
      case SessionStatus.cancelled:
        return AppColors.error;
    }
  }
}
