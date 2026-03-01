import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/forum.dart';
import '../../domain/repositories/forum_repository.dart';

part 'forum_event.dart';
part 'forum_state.dart';

class ForumBloc extends Bloc<ForumEvent, ForumState> {
  final ForumRepository repository;

  ForumBloc({required this.repository}) : super(ForumInitial()) {
    on<LoadForums>(_onLoadForums);
    on<LoadDiscussions>(_onLoadDiscussions);
    on<LoadPosts>(_onLoadPosts);
    on<AddNewDiscussion>(_onAddDiscussion);
    on<AddReplyToPost>(_onAddReply);
    on<TogglePinDiscussion>(_onTogglePin);
    on<DeleteDiscussion>(_onDeleteDiscussion);
  }

  Future<void> _onLoadForums(LoadForums event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.getForumsByCourse(event.courseId);
    result.fold(
      (f) => emit(ForumError(message: f.message)),
      (forums) => emit(ForumsLoaded(forums: forums)),
    );
  }

  Future<void> _onLoadDiscussions(
    LoadDiscussions event,
    Emitter<ForumState> emit,
  ) async {
    emit(ForumLoading());
    final result = await repository.getDiscussions(event.forumId);
    result.fold(
      (f) => emit(ForumError(message: f.message)),
      (discussions) => emit(DiscussionsLoaded(discussions: discussions)),
    );
  }

  Future<void> _onLoadPosts(LoadPosts event, Emitter<ForumState> emit) async {
    emit(ForumLoading());
    final result = await repository.getDiscussionPosts(event.discussionId);
    result.fold(
      (f) => emit(ForumError(message: f.message)),
      (posts) => emit(PostsLoaded(posts: posts)),
    );
  }

  Future<void> _onAddDiscussion(
    AddNewDiscussion event,
    Emitter<ForumState> emit,
  ) async {
    emit(ForumLoading());
    final result = await repository.addDiscussion(
      event.forumId,
      event.subject,
      event.message,
    );
    result.fold((f) => emit(ForumError(message: f.message)), (_) {
      emit(ForumActionSuccess());
      add(LoadDiscussions(forumId: event.forumId));
    });
  }

  Future<void> _onAddReply(
    AddReplyToPost event,
    Emitter<ForumState> emit,
  ) async {
    emit(ForumLoading());
    final result = await repository.addReply(
      event.postId,
      event.subject,
      event.message,
    );
    result.fold((f) => emit(ForumError(message: f.message)), (_) {
      emit(ForumActionSuccess());
      add(LoadPosts(discussionId: event.discussionId));
    });
  }

  Future<void> _onTogglePin(
    TogglePinDiscussion event,
    Emitter<ForumState> emit,
  ) async {
    final result = await repository.togglePinDiscussion(
      event.discussionId,
      event.pinned,
    );
    result.fold((f) => emit(ForumError(message: f.message)), (_) {
      emit(ForumActionSuccess());
      add(LoadDiscussions(forumId: event.forumId));
    });
  }

  Future<void> _onDeleteDiscussion(
    DeleteDiscussion event,
    Emitter<ForumState> emit,
  ) async {
    final result = await repository.deletePost(event.postId);
    result.fold((f) => emit(ForumError(message: f.message)), (_) {
      emit(ForumActionSuccess());
      add(LoadDiscussions(forumId: event.forumId));
    });
  }
}
