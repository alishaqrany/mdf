import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/social_entities.dart';
import '../../domain/repositories/social_repository.dart';

// ─── Events ───
abstract class StudyNotesEvent extends Equatable {
  const StudyNotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadCourseNotes extends StudyNotesEvent {
  final int courseId;
  const LoadCourseNotes(this.courseId);
  @override
  List<Object?> get props => [courseId];
}

class LoadGroupNotes extends StudyNotesEvent {
  final int groupId;
  const LoadGroupNotes(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class CreateNote extends StudyNotesEvent {
  final String title;
  final String content;
  final int courseId;
  final int? groupId;
  final NoteVisibility visibility;
  final List<String> tags;

  const CreateNote({
    required this.title,
    required this.content,
    required this.courseId,
    this.groupId,
    this.visibility = NoteVisibility.course,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [title, courseId];
}

class UpdateNote extends StudyNotesEvent {
  final int noteId;
  final String title;
  final String content;
  final List<String> tags;

  const UpdateNote({
    required this.noteId,
    required this.title,
    required this.content,
    this.tags = const [],
  });

  @override
  List<Object?> get props => [noteId, title];
}

class DeleteNote extends StudyNotesEvent {
  final int noteId;
  const DeleteNote(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class ToggleLikeNote extends StudyNotesEvent {
  final int noteId;
  const ToggleLikeNote(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class ToggleBookmarkNote extends StudyNotesEvent {
  final int noteId;
  const ToggleBookmarkNote(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class LoadNoteComments extends StudyNotesEvent {
  final int noteId;
  const LoadNoteComments(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class AddNoteComment extends StudyNotesEvent {
  final int noteId;
  final String content;
  const AddNoteComment({required this.noteId, required this.content});
  @override
  List<Object?> get props => [noteId, content];
}

// ─── States ───
abstract class StudyNotesState extends Equatable {
  const StudyNotesState();
  @override
  List<Object?> get props => [];
}

class StudyNotesInitial extends StudyNotesState {}

class StudyNotesLoading extends StudyNotesState {}

class StudyNotesLoaded extends StudyNotesState {
  final List<StudyNote> notes;
  const StudyNotesLoaded(this.notes);
  @override
  List<Object?> get props => [notes];
}

class NoteCreated extends StudyNotesState {
  final StudyNote note;
  const NoteCreated(this.note);
  @override
  List<Object?> get props => [note];
}

class NoteUpdated extends StudyNotesState {
  final StudyNote note;
  const NoteUpdated(this.note);
  @override
  List<Object?> get props => [note];
}

class NoteCommentsLoaded extends StudyNotesState {
  final List<NoteComment> comments;
  const NoteCommentsLoaded(this.comments);
  @override
  List<Object?> get props => [comments];
}

class StudyNotesActionSuccess extends StudyNotesState {
  final String action;
  const StudyNotesActionSuccess(this.action);
  @override
  List<Object?> get props => [action];
}

class StudyNotesError extends StudyNotesState {
  final String message;
  const StudyNotesError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class StudyNotesBloc extends Bloc<StudyNotesEvent, StudyNotesState> {
  final SocialRepository repository;

  StudyNotesBloc({required this.repository}) : super(StudyNotesInitial()) {
    on<LoadCourseNotes>(_onLoadCourseNotes);
    on<LoadGroupNotes>(_onLoadGroupNotes);
    on<CreateNote>(_onCreateNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
    on<ToggleLikeNote>(_onToggleLike);
    on<ToggleBookmarkNote>(_onToggleBookmark);
    on<LoadNoteComments>(_onLoadComments);
    on<AddNoteComment>(_onAddComment);
  }

  Future<void> _onLoadCourseNotes(
    LoadCourseNotes event,
    Emitter<StudyNotesState> emit,
  ) async {
    emit(StudyNotesLoading());
    final result = await repository.getCourseNotes(event.courseId);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (notes) => emit(StudyNotesLoaded(notes)),
    );
  }

  Future<void> _onLoadGroupNotes(
    LoadGroupNotes event,
    Emitter<StudyNotesState> emit,
  ) async {
    emit(StudyNotesLoading());
    final result = await repository.getGroupNotes(event.groupId);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (notes) => emit(StudyNotesLoaded(notes)),
    );
  }

  Future<void> _onCreateNote(
    CreateNote event,
    Emitter<StudyNotesState> emit,
  ) async {
    emit(StudyNotesLoading());
    final result = await repository.createNote(
      title: event.title,
      content: event.content,
      courseId: event.courseId,
      groupId: event.groupId,
      visibility: event.visibility,
      tags: event.tags,
    );
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (note) => emit(NoteCreated(note)),
    );
  }

  Future<void> _onUpdateNote(
    UpdateNote event,
    Emitter<StudyNotesState> emit,
  ) async {
    emit(StudyNotesLoading());
    final result = await repository.updateNote(
      noteId: event.noteId,
      title: event.title,
      content: event.content,
      tags: event.tags,
    );
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (note) => emit(NoteUpdated(note)),
    );
  }

  Future<void> _onDeleteNote(
    DeleteNote event,
    Emitter<StudyNotesState> emit,
  ) async {
    final result = await repository.deleteNote(event.noteId);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (_) => emit(const StudyNotesActionSuccess('deleted')),
    );
  }

  Future<void> _onToggleLike(
    ToggleLikeNote event,
    Emitter<StudyNotesState> emit,
  ) async {
    final result = await repository.toggleLikeNote(event.noteId);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (_) => emit(const StudyNotesActionSuccess('liked')),
    );
  }

  Future<void> _onToggleBookmark(
    ToggleBookmarkNote event,
    Emitter<StudyNotesState> emit,
  ) async {
    final result = await repository.toggleBookmarkNote(event.noteId);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (_) => emit(const StudyNotesActionSuccess('bookmarked')),
    );
  }

  Future<void> _onLoadComments(
    LoadNoteComments event,
    Emitter<StudyNotesState> emit,
  ) async {
    emit(StudyNotesLoading());
    final result = await repository.getNoteComments(event.noteId);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (comments) => emit(NoteCommentsLoaded(comments)),
    );
  }

  Future<void> _onAddComment(
    AddNoteComment event,
    Emitter<StudyNotesState> emit,
  ) async {
    final result = await repository.addNoteComment(event.noteId, event.content);
    result.fold(
      (f) => emit(StudyNotesError(f.message)),
      (_) => emit(const StudyNotesActionSuccess('comment_added')),
    );
  }
}
