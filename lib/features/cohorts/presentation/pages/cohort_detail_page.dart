import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../../data/models/cohort_model.dart';
import '../bloc/cohort_bloc.dart';

/// Page showing members of a specific cohort, with add/remove capability.
class CohortDetailPage extends StatelessWidget {
  final int cohortId;
  final String cohortName;

  const CohortDetailPage({
    super.key,
    required this.cohortId,
    this.cohortName = '',
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = CohortBloc(apiClient: GetIt.instance<MoodleApiClient>());
        bloc.setCohortName(cohortName);
        bloc.add(LoadCohortMembers(cohortid: cohortId));
        return bloc;
      },
      child: _CohortDetailView(cohortId: cohortId, cohortName: cohortName),
    );
  }
}

class _CohortDetailView extends StatelessWidget {
  final int cohortId;
  final String cohortName;

  const _CohortDetailView({required this.cohortId, required this.cohortName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(cohortName.isNotEmpty ? cohortName : tr('cohorts.members')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: tr('cohorts.add_member'),
            onPressed: () => _showAddMemberDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<CohortBloc, CohortState>(
        listener: (context, state) {
          if (state is CohortError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CohortLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CohortMembersLoaded) {
            if (state.members.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_off_rounded,
                      size: 64,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('cohorts.no_members'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _showAddMemberDialog(context),
                      icon: const Icon(Icons.person_add),
                      label: Text(tr('cohorts.add_member')),
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<CohortBloc>().add(
                  LoadCohortMembers(cohortid: cohortId),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '${tr('cohorts.members')} (${state.members.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.members.length,
                      itemBuilder: (context, index) {
                        final member = state.members[index];
                        return _MemberTile(member: member, cohortId: cohortId);
                      },
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is CohortError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.read<CohortBloc>().add(
                      LoadCohortMembers(cohortid: cohortId),
                    ),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<CohortBloc>(),
        child: _AddMemberSheet(cohortId: cohortId),
      ),
    );
  }
}

// ─── Member Tile ───
class _MemberTile extends StatelessWidget {
  final CohortMemberModel member;
  final int cohortId;

  const _MemberTile({required this.member, required this.cohortId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            member.fullname.isNotEmpty ? member.fullname[0].toUpperCase() : '?',
            style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        title: Text(member.fullname, style: theme.textTheme.titleSmall),
        subtitle: member.email.isNotEmpty
            ? Text(member.email, style: theme.textTheme.bodySmall)
            : null,
        trailing: IconButton(
          icon: Icon(
            Icons.person_remove_rounded,
            color: theme.colorScheme.error,
          ),
          tooltip: tr('cohorts.remove_member'),
          onPressed: () => _confirmRemove(context),
        ),
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('cohorts.remove_member')),
        content: Text(tr('cohorts.remove_confirm', args: [member.fullname])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CohortBloc>().add(
                RemoveMembersFromCohort(
                  cohortid: cohortId,
                  userids: [member.userid],
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(tr('common.remove')),
          ),
        ],
      ),
    );
  }
}

// ─── Add Member Bottom Sheet ───
class _AddMemberSheet extends StatefulWidget {
  final int cohortId;
  const _AddMemberSheet({required this.cohortId});

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  final Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final apiClient = GetIt.instance<MoodleApiClient>();
      final response = await apiClient.call(
        MoodleApiEndpoints.getUsers,
        params: {'criteria[0][key]': 'email', 'criteria[0][value]': '%'},
      );
      if (response is Map && response.containsKey('users')) {
        setState(() {
          _users = (response['users'] as List)
              .cast<Map<String, dynamic>>()
              .map(
                (u) => {
                  'id': u['id'],
                  'fullname': '${u['firstname'] ?? ''} ${u['lastname'] ?? ''}'
                      .trim(),
                  'email': u['email'] ?? '',
                },
              )
              .toList();
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('cohorts.add_member'), style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          if (_isLoading)
            const LinearProgressIndicator()
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final userId = user['id'] as int;
                  return CheckboxListTile(
                    value: _selectedUserIds.contains(userId),
                    onChanged: (checked) {
                      setState(() {
                        if (checked ?? false) {
                          _selectedUserIds.add(userId);
                        } else {
                          _selectedUserIds.remove(userId);
                        }
                      });
                    },
                    title: Text(user['fullname'] as String),
                    subtitle: Text(user['email'] as String),
                    secondary: CircleAvatar(
                      child: Text(
                        (user['fullname'] as String).isNotEmpty
                            ? (user['fullname'] as String)[0].toUpperCase()
                            : '?',
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedUserIds.isEmpty
                ? null
                : () {
                    context.read<CohortBloc>().add(
                      AddMembersToCohort(
                        cohortid: widget.cohortId,
                        userids: _selectedUserIds.toList(),
                      ),
                    );
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.person_add),
            label: Text(
              '${tr('cohorts.add_selected')} (${_selectedUserIds.length})',
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
