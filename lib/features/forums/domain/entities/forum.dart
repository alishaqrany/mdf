import 'package:equatable/equatable.dart';

/// A course forum.
class Forum extends Equatable {
  final int id;
  final int courseId;
  final String name;
  final String? intro;
  final String? type; // news, general, eachuser, qanda, single, blog

  const Forum({
    required this.id,
    required this.courseId,
    required this.name,
    this.intro,
    this.type,
  });

  @override
  List<Object?> get props => [id, courseId, name];
}

/// A discussion in a forum.
class ForumDiscussion extends Equatable {
  final int id;
  final int forumId;
  final String name;
  final String? message;
  final int? userId;
  final String? userFullName;
  final String? userPictureUrl;
  final int? timeModified;
  final int? numReplies;
  final bool? pinned;

  const ForumDiscussion({
    required this.id,
    required this.forumId,
    required this.name,
    this.message,
    this.userId,
    this.userFullName,
    this.userPictureUrl,
    this.timeModified,
    this.numReplies,
    this.pinned,
  });

  @override
  List<Object?> get props => [id, forumId, name];
}

/// A post in a discussion.
class ForumPost extends Equatable {
  final int id;
  final int discussionId;
  final int? parentId;
  final String? subject;
  final String? message;
  final int? userId;
  final String? userFullName;
  final String? userPictureUrl;
  final int? timeCreated;

  const ForumPost({
    required this.id,
    required this.discussionId,
    this.parentId,
    this.subject,
    this.message,
    this.userId,
    this.userFullName,
    this.userPictureUrl,
    this.timeCreated,
  });

  @override
  List<Object?> get props => [id, discussionId];
}
