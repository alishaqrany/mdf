import '../../domain/entities/forum.dart';

class ForumModel extends Forum {
  const ForumModel({
    required super.id,
    required super.courseId,
    required super.name,
    super.intro,
    super.type,
  });

  factory ForumModel.fromJson(Map<String, dynamic> json) {
    return ForumModel(
      id: json['id'] as int,
      courseId: json['course'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      intro: json['intro'] as String?,
      type: json['type'] as String?,
    );
  }
}

class ForumDiscussionModel extends ForumDiscussion {
  const ForumDiscussionModel({
    required super.id,
    required super.forumId,
    required super.name,
    super.message,
    super.userId,
    super.userFullName,
    super.userPictureUrl,
    super.timeModified,
    super.numReplies,
    super.pinned,
  });

  factory ForumDiscussionModel.fromJson(Map<String, dynamic> json) {
    return ForumDiscussionModel(
      id: json['discussion'] as int? ?? json['id'] as int? ?? 0,
      forumId: json['forum'] as int? ?? 0,
      name: json['name'] as String? ?? json['subject'] as String? ?? '',
      message: json['message'] as String?,
      userId: json['userid'] as int?,
      userFullName: json['userfullname'] as String?,
      userPictureUrl: json['userpictureurl'] as String?,
      timeModified: json['timemodified'] as int?,
      numReplies: json['numreplies'] as int?,
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}

class ForumPostModel extends ForumPost {
  const ForumPostModel({
    required super.id,
    required super.discussionId,
    super.parentId,
    super.subject,
    super.message,
    super.userId,
    super.userFullName,
    super.userPictureUrl,
    super.timeCreated,
  });

  factory ForumPostModel.fromJson(Map<String, dynamic> json) {
    return ForumPostModel(
      id: json['id'] as int,
      discussionId: json['discussion'] as int? ?? 0,
      parentId: json['parent'] as int?,
      subject: json['subject'] as String?,
      message: json['message'] as String?,
      userId: json['userid'] as int?,
      userFullName: json['userfullname'] as String?,
      userPictureUrl: json['userpictureurl'] as String?,
      timeCreated: json['timecreated'] as int?,
    );
  }
}
