import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/injection.dart';
import '../../domain/entities/social_entities.dart';
import '../bloc/study_notes_bloc.dart';
import '../widgets/note_card.dart';

class StudyNotesPage extends StatelessWidget {
  final int? courseId;
  final int? groupId;

  const StudyNotesPage({super.key, this.courseId, this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<StudyNotesBloc>()
        ..add(
          groupId != null
              ? LoadGroupNotes(groupId!)
              : LoadCourseNotes(courseId ?? 0),
        ),
      child: _StudyNotesView(courseId: courseId ?? 0, groupId: groupId),
    );
  }
}

class _StudyNotesView extends StatelessWidget {
  final int courseId;
  final int? groupId;

  const _StudyNotesView({required this.courseId, this.groupId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr('social.study_notes'))),
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_note_fab',
        onPressed: () => _showNoteEditor(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: BlocConsumer<StudyNotesBloc, StudyNotesState>(
        listener: (context, state) {
          if (state is NoteCreated || state is NoteUpdated) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(tr('social.note_saved'))));
            context.read<StudyNotesBloc>().add(
              groupId != null
                  ? LoadGroupNotes(groupId!)
                  : LoadCourseNotes(courseId),
            );
          } else if (state is StudyNotesActionSuccess) {
            context.read<StudyNotesBloc>().add(
              groupId != null
                  ? LoadGroupNotes(groupId!)
                  : LoadCourseNotes(courseId),
            );
          }
        },
        builder: (context, state) {
          if (state is StudyNotesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is StudyNotesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: theme.textTheme.bodyLarge),
                ],
              ),
            );
          }

          if (state is StudyNotesLoaded) {
            if (state.notes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 80,
                      color: AppColors.textTertiaryLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr('social.no_notes'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<StudyNotesBloc>().add(
                  groupId != null
                      ? LoadGroupNotes(groupId!)
                      : LoadCourseNotes(courseId),
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: state.notes.length,
                itemBuilder: (context, index) {
                  return FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: index * 60),
                    child: NoteCard(
                      note: state.notes[index],
                      onLike: () => context.read<StudyNotesBloc>().add(
                        ToggleLikeNote(state.notes[index].id),
                      ),
                      onBookmark: () => context.read<StudyNotesBloc>().add(
                        ToggleBookmarkNote(state.notes[index].id),
                      ),
                      onTap: () => _showNoteDetail(context, state.notes[index]),
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

  void _showNoteEditor(BuildContext context, {StudyNote? note}) {
    final titleCtrl = TextEditingController(text: note?.title ?? '');
    final contentCtrl = TextEditingController(text: note?.content ?? '');
    final tagsCtrl = TextEditingController(text: note?.tags.join(', ') ?? '');
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  note != null ? tr('social.edit_note') : tr('social.new_note'),
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: tr('social.note_title'),
                    prefixIcon: const Icon(Icons.title_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? tr('validation.required')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentCtrl,
                  decoration: InputDecoration(
                    labelText: tr('social.note_content'),
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  minLines: 4,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? tr('validation.required')
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tagsCtrl,
                  decoration: InputDecoration(
                    labelText: tr('social.tags'),
                    prefixIcon: const Icon(Icons.tag_rounded),
                    hintText: 'math, algebra, chapter1',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final tags = tagsCtrl.text
                          .split(',')
                          .map((t) => t.trim())
                          .where((t) => t.isNotEmpty)
                          .toList();
                      if (note != null) {
                        context.read<StudyNotesBloc>().add(
                          UpdateNote(
                            noteId: note.id,
                            title: titleCtrl.text.trim(),
                            content: contentCtrl.text.trim(),
                            tags: tags,
                          ),
                        );
                      } else {
                        context.read<StudyNotesBloc>().add(
                          CreateNote(
                            title: titleCtrl.text.trim(),
                            content: contentCtrl.text.trim(),
                            courseId: courseId,
                            groupId: groupId,
                            tags: tags,
                          ),
                        );
                      }
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(tr('social.save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNoteDetail(BuildContext context, StudyNote note) {
    final theme = Theme.of(context);

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
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(note.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text(
                      note.authorName.isNotEmpty
                          ? note.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(note.authorName, style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    DateFormat.yMd().format(note.createdAt),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(note.content, style: theme.textTheme.bodyLarge),
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  children: note.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          padding: EdgeInsets.zero,
                          labelStyle: theme.textTheme.labelSmall,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _NoteActionButton(
                    icon: note.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '${note.likes}',
                    color: note.isLiked ? AppColors.error : null,
                    onTap: () {
                      context.read<StudyNotesBloc>().add(
                        ToggleLikeNote(note.id),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: 16),
                  _NoteActionButton(
                    icon: note.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    label: tr('social.bookmark'),
                    color: note.isBookmarked ? AppColors.warning : null,
                    onTap: () {
                      context.read<StudyNotesBloc>().add(
                        ToggleBookmarkNote(note.id),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(width: 16),
                  _NoteActionButton(
                    icon: Icons.comment_outlined,
                    label: '${note.commentCount}',
                    onTap: () {
                      // TODO: Show comments
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _NoteActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.textSecondaryLight),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color ?? AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
