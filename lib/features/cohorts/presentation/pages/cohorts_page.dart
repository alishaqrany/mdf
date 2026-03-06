import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/moodle_api_client.dart';
import '../../data/models/cohort_model.dart';
import '../bloc/cohort_bloc.dart';

/// Admin page listing all cohorts with member counts.
class CohortsPage extends StatelessWidget {
  const CohortsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CohortBloc(apiClient: GetIt.instance<MoodleApiClient>())
            ..add(const LoadCohorts()),
      child: const _CohortsView(),
    );
  }
}

class _CohortsView extends StatefulWidget {
  const _CohortsView();

  @override
  State<_CohortsView> createState() => _CohortsViewState();
}

class _CohortsViewState extends State<_CohortsView> {
  final _searchController = TextEditingController();

  void _showCreateCohortDialog(BuildContext outerContext) {
    final nameCtrl = TextEditingController();
    final idnumberCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool visible = true;

    showDialog(
      context: outerContext,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('cohorts.create')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: tr('cohorts.name'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idnumberCtrl,
                  decoration: InputDecoration(
                    labelText: tr('cohorts.idnumber'),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: tr('cohorts.description_label'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(tr('cohorts.visible')),
                  value: visible,
                  onChanged: (v) => setDialogState(() => visible = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(tr('common.cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                outerContext.read<CohortBloc>().add(
                  CreateCohort(
                    name: nameCtrl.text.trim(),
                    idnumber: idnumberCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    visible: visible,
                  ),
                );
                Navigator.pop(dialogCtx);
              },
              child: Text(tr('common.create')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('cohorts.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCohortDialog(context),
        icon: const Icon(Icons.group_add_rounded),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Text(
            tr('cohorts.create'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: tr('cohorts.search_hint'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<CohortBloc>().add(const LoadCohorts());
                  },
                ),
              ),
              onSubmitted: (value) {
                context.read<CohortBloc>().add(LoadCohorts(search: value));
              },
            ),
          ),

          // Cohort list
          Expanded(
            child: BlocConsumer<CohortBloc, CohortState>(
              listener: (context, state) {
                if (state is CohortError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
                if (state is CohortActionSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                if (state is CohortLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is CohortsLoaded) {
                  if (state.cohorts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr('cohorts.no_cohorts'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CohortBloc>().add(
                        LoadCohorts(search: _searchController.text),
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.cohorts.length,
                      itemBuilder: (context, index) {
                        return _CohortCard(cohort: state.cohorts[index]);
                      },
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
                            const LoadCohorts(),
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
          ),
        ],
      ),
    );
  }
}

// ─── Cohort Card ───
class _CohortCard extends StatelessWidget {
  final CohortModel cohort;
  const _CohortCard({required this.cohort});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.groups_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(cohort.name, style: theme.textTheme.titleSmall),
        subtitle: Text(
          cohort.description.isNotEmpty
              ? cohort.description
              : cohort.idnumber.isNotEmpty
              ? 'ID: ${cohort.idnumber}'
              : tr('cohorts.no_description'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              avatar: const Icon(Icons.person, size: 16),
              label: Text('${cohort.membercount}'),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          context.read<CohortBloc>().setCohortName(cohort.name);
          context.push(
            '/admin/cohorts/${cohort.id}',
            extra: {'cohortName': cohort.name},
          );
        },
        onLongPress: () => _confirmDelete(context),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('cohorts.delete_title')),
        content: Text(tr('cohorts.delete_confirm', args: [cohort.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(tr('common.cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CohortBloc>().add(DeleteCohort(cohortid: cohort.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
            ),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
  }
}
