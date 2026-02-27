part of 'forum_bloc.dart';

abstract class ForumState extends Equatable {
  const ForumState();
  @override
  List<Object?> get props => [];
}

class ForumInitial extends ForumState {}

class ForumLoading extends ForumState {}

class ForumsLoaded extends ForumState {
  final List<Forum> forums;
  const ForumsLoaded({required this.forums});
  @override
  List<Object?> get props => [forums];
}

class DiscussionsLoaded extends ForumState {
  final List<ForumDiscussion> discussions;
  const DiscussionsLoaded({required this.discussions});
  @override
  List<Object?> get props => [discussions];
}

class PostsLoaded extends ForumState {
  final List<ForumPost> posts;
  const PostsLoaded({required this.posts});
  @override
  List<Object?> get props => [posts];
}

class ForumActionSuccess extends ForumState {}

class ForumError extends ForumState {
  final String message;
  const ForumError({required this.message});
  @override
  List<Object?> get props => [message];
}
