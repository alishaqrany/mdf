part of 'forum_bloc.dart';

abstract class ForumEvent extends Equatable {
  const ForumEvent();
  @override
  List<Object?> get props => [];
}

class LoadForums extends ForumEvent {
  final int courseId;
  const LoadForums({required this.courseId});
  @override
  List<Object?> get props => [courseId];
}

class LoadDiscussions extends ForumEvent {
  final int forumId;
  const LoadDiscussions({required this.forumId});
  @override
  List<Object?> get props => [forumId];
}

class LoadPosts extends ForumEvent {
  final int discussionId;
  const LoadPosts({required this.discussionId});
  @override
  List<Object?> get props => [discussionId];
}

class AddNewDiscussion extends ForumEvent {
  final int forumId;
  final String subject;
  final String message;
  const AddNewDiscussion({
    required this.forumId,
    required this.subject,
    required this.message,
  });
  @override
  List<Object?> get props => [forumId, subject, message];
}

class AddReplyToPost extends ForumEvent {
  final int postId;
  final int discussionId;
  final String subject;
  final String message;
  const AddReplyToPost({
    required this.postId,
    required this.discussionId,
    required this.subject,
    required this.message,
  });
  @override
  List<Object?> get props => [postId, discussionId, subject, message];
}

class TogglePinDiscussion extends ForumEvent {
  final int discussionId;
  final int forumId;
  final bool pinned;
  const TogglePinDiscussion({
    required this.discussionId,
    required this.forumId,
    required this.pinned,
  });
  @override
  List<Object?> get props => [discussionId, forumId, pinned];
}

class DeleteDiscussion extends ForumEvent {
  final int postId;
  final int forumId;
  const DeleteDiscussion({required this.postId, required this.forumId});
  @override
  List<Object?> get props => [postId, forumId];
}
