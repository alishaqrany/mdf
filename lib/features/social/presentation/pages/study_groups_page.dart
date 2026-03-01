import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/study_groups_bloc.dart';
import '../widgets/group_card.dart';

class StudyGroupsPage extends StatelessWidget {
  final int? courseId;

  const StudyGroupsPage({super.key, this.courseId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<StudyGroupsBloc>()..add(LoadStudyGroups(courseId: courseId)),
      child: _StudyGroupsView(courseId: courseId),
    );
  }
}

class _StudyGroupsView extends StatelessWidget {
  final int? courseId;

  const _StudyGroupsView({this.courseId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('social.study_groups')),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // TODO: Search groups
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create_group_fab',
        onPressed: () => _showCreateGroupDialog(context),
        icon: const Icon(Icons.group_add_rounded),
        label: Text(tr('social.create_group')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<StudyGroupsBloc, StudyGroupsState>(
        listener: (context, state) {
          if (state is StudyGroupCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('social.group_created'))),
            );
            context.read<StudyGroupsBloc>().add(
              LoadStudyGroups(courseId: courseId),
            );
          } else if (state is StudyGroupActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            context.read<StudyGroupsBloc>().add(
              LoadStudyGroups(courseId: courseId),
            );
          }
        },
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
                  Text(state.message, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<StudyGroupsBloc>().add(
                      LoadStudyGroups(courseId: courseId),
                    ),
                    child: Text(tr('common.retry')),
                  ),
                ],
              ),
            );
          }

          if (state is StudyGroupsLoaded) {
            if (state.groups.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StudyGroupsBloc>().add(
                  LoadStudyGroups(courseId: courseId),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: state.groups.length,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: index * 60),
                    child: GroupCard(
                      group: state.groups[index],
                      onTap: () => context.push(
                        '/student/group/${state.groups[index].id}',
                      ),
                      onJoin: () => context.read<StudyGroupsBloc>().add(
                        JoinStudyGroup(state.groups[index].id),
                      ),
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups_outlined,
            size: 80,
            color: AppColors.textTertiaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            tr('social.no_groups'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateGroupDialog(context),
            icon: const Icon(Icons.group_add_rounded),
            label: Text(tr('social.create_group')),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('social.create_group'),
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: tr('social.group_name'),
                  prefixIcon: const Icon(Icons.group_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? tr('validation.required')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: tr('social.description'),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    final authState = context.read<AuthBloc>().state;
                    final cId = courseId ??
                        (authState is AuthAuthenticated ? 1 : 0);
                    context.read<StudyGroupsBloc>().add(
                      CreateStudyGroup(
                        name: nameController.text.trim(),
                        courseId: cId,
                        description: descController.text.trim().isNotEmpty
                            ? descController.text.trim()
                            : null,
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
            ],
          ),
        ),
      ),
    );
  }
}
