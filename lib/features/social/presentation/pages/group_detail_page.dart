import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/social_entities.dart';
import '../bloc/study_groups_bloc.dart';
import '../bloc/collaborative_bloc.dart';
import '../bloc/study_notes_bloc.dart';

class GroupDetailPage extends StatelessWidget {
  final int groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<StudyGroupsBloc>()..add(LoadGroupDetail(groupId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<CollaborativeBloc>()..add(LoadGroupSessions(groupId)),
        ),
        BlocProvider(
          create: (_) => sl<StudyNotesBloc>()..add(LoadGroupNotes(groupId)),
        ),
      ],
      child: _GroupDetailView(groupId: groupId),
    );
  }
}

class _GroupDetailView extends StatelessWidget {
  final int groupId;

  const _GroupDetailView({required this.groupId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: BlocBuilder<StudyGroupsBloc, StudyGroupsState>(
        builder: (context, state) {
          if (state is StudyGroupsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudyGroupsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<StudyGroupsBloc>().add(
                      LoadGroupDetail(groupId),
                    ),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is StudyGroupDetailLoaded) {
            return _buildContent(context, theme, state.group, state.members);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ThemeData theme,
    StudyGroup group,
    List<GroupMember> members,
  ) {
    return CustomScrollView(
      slivers: [
        // ─── Header ───
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.groups_rounded,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          actions: [
            if (group.currentUserRole == GroupMemberRole.admin)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    context.read<StudyGroupsBloc>().add(
                      DeleteStudyGroup(group.id),
                    );
                    context.pop();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(tr('social.delete_group')),
                  ),
                ],
              ),
          ],
        ),

        // ─── Group Info ───
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (group.description != null &&
                          group.description!.isNotEmpty) ...[
                        Text(
                          group.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.people_rounded,
                            label: '${group.memberCount}/${group.maxMembers}',
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: group.isPublic
                                ? Icons.public_rounded
                                : Icons.lock_rounded,
                            label: group.isPublic
                                ? tr('social.public')
                                : tr('social.private'),
                            color: group.isPublic
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          if (group.courseName != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InfoChip(
                                icon: Icons.school_rounded,
                                label: group.courseName!,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // ─── Action Buttons ───
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/student/group/$groupId/notes'),
                      icon: const Icon(Icons.note_alt_rounded, size: 20),
                      label: Text(tr('social.notes')),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          context.push('/student/group/$groupId/sessions'),
                      icon: const Icon(Icons.co_present_rounded, size: 20),
                      label: Text(tr('social.sessions')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ─── Members Section ───
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                '${tr('social.members')} (${members.length})',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),

        // ─── Members List ───
        if (members.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tr('social.no_members'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final member = members[index];
              return FadeInUp(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: 250 + (index * 50)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: member.profileImageUrl != null
                        ? CachedNetworkImageProvider(member.profileImageUrl!)
                        : null,
                    child: member.profileImageUrl == null
                        ? Text(member.fullName[0].toUpperCase())
                        : null,
                  ),
                  title: Text(member.fullName),
                  subtitle: Text(
                    member.role.name.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: member.role == GroupMemberRole.admin
                          ? AppColors.warning
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  trailing: member.isOnline
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        )
                      : null,
                ),
              );
            }, childCount: members.length),
          ),

        // ─── Sessions Preview ───
        SliverToBoxAdapter(
          child: FadeInUp(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 300),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                tr('social.upcoming_sessions'),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: BlocBuilder<CollaborativeBloc, CollaborativeState>(
            builder: (context, state) {
              if (state is CollaborativeSessionsLoaded) {
                final active = state.sessions
                    .where(
                      (s) =>
                          s.status == SessionStatus.scheduled ||
                          s.status == SessionStatus.active,
                    )
                    .take(3)
                    .toList();
                if (active.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      tr('social.no_sessions'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: active
                      .map(
                        (s) => ListTile(
                          leading: Icon(
                            s.isActive ? Icons.circle : Icons.schedule_rounded,
                            color: s.isActive
                                ? AppColors.success
                                : AppColors.info,
                            size: 20,
                          ),
                          title: Text(s.title),
                          subtitle: Text(
                            DateFormat.yMd().add_Hm().format(s.startTime),
                          ),
                          trailing: Text(
                            '${s.participantCount}/${s.maxParticipants}',
                          ),
                          onTap: () =>
                              context.push('/student/group/$groupId/sessions'),
                        ),
                      )
                      .toList(),
                );
              }
              return const SizedBox();
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
