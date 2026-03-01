import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────
//  Study Group
// ─────────────────────────────────────────────

/// A study group that students create or join within a course.
class StudyGroup extends Equatable {
  final int id;
  final String name;
  final String? description;
  final int courseId;
  final String? courseName;
  final int createdBy;
  final String? creatorName;
  final String? imageUrl;
  final bool isPublic;
  final int memberCount;
  final int maxMembers;
  final DateTime createdAt;
  final List<GroupMember> members;
  final GroupMemberRole? currentUserRole;

  const StudyGroup({
    required this.id,
    required this.name,
    this.description,
    required this.courseId,
    this.courseName,
    required this.createdBy,
    this.creatorName,
    this.imageUrl,
    this.isPublic = true,
    this.memberCount = 0,
    this.maxMembers = 30,
    required this.createdAt,
    this.members = const [],
    this.currentUserRole,
  });

  bool get isFull => memberCount >= maxMembers;

  @override
  List<Object?> get props => [id, name, courseId];
}

/// A member within a study group.
class GroupMember extends Equatable {
  final int userId;
  final String fullName;
  final String? profileImageUrl;
  final GroupMemberRole role;
  final DateTime joinedAt;
  final bool isOnline;

  const GroupMember({
    required this.userId,
    required this.fullName,
    this.profileImageUrl,
    this.role = GroupMemberRole.member,
    required this.joinedAt,
    this.isOnline = false,
  });

  @override
  List<Object?> get props => [userId, fullName];
}

enum GroupMemberRole { admin, moderator, member }

// ─────────────────────────────────────────────
//  Study Notes
// ─────────────────────────────────────────────

/// A shared study note within a course.
class StudyNote extends Equatable {
  final int id;
  final String title;
  final String content;
  final int authorId;
  final String authorName;
  final String? authorImageUrl;
  final int courseId;
  final String? courseName;
  final String? moduleName;
  final int likes;
  final bool isLiked;
  final bool isBookmarked;
  final int commentCount;
  final NoteVisibility visibility;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudyNote({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.courseId,
    this.courseName,
    this.moduleName,
    this.likes = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    this.commentCount = 0,
    this.visibility = NoteVisibility.course,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, courseId];
}

/// A comment on a study note.
class NoteComment extends Equatable {
  final int id;
  final int noteId;
  final int authorId;
  final String authorName;
  final String? authorImageUrl;
  final String content;
  final DateTime createdAt;

  const NoteComment({
    required this.id,
    required this.noteId,
    required this.authorId,
    required this.authorName,
    this.authorImageUrl,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, noteId];
}

enum NoteVisibility { personal, group, course, public }

// ─────────────────────────────────────────────
//  Peer Review
// ─────────────────────────────────────────────

/// A peer review for workshop assignments.
class PeerReview extends Equatable {
  final int id;
  final int workshopId;
  final String workshopName;
  final int courseId;
  final String? courseName;
  final int submitterId;
  final String submitterName;
  final String? submitterImageUrl;
  final int? reviewerId;
  final String? reviewerName;
  final double? rating;
  final double maxRating;
  final String? feedback;
  final PeerReviewStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? submissionContent;
  final List<String> submissionAttachments;

  const PeerReview({
    required this.id,
    required this.workshopId,
    required this.workshopName,
    required this.courseId,
    this.courseName,
    required this.submitterId,
    required this.submitterName,
    this.submitterImageUrl,
    this.reviewerId,
    this.reviewerName,
    this.rating,
    this.maxRating = 100,
    this.feedback,
    this.status = PeerReviewStatus.pending,
    this.submittedAt,
    this.reviewedAt,
    this.submissionContent,
    this.submissionAttachments = const [],
  });

  double get ratingPercentage =>
      rating != null && maxRating > 0 ? (rating! / maxRating) * 100 : 0;

  @override
  List<Object?> get props => [id, workshopId, submitterId];
}

enum PeerReviewStatus { pending, inProgress, completed, overdue }

// ─────────────────────────────────────────────
//  Collaborative Session
// ─────────────────────────────────────────────

/// A live collaborative study session within a group.
class CollaborativeSession extends Equatable {
  final int id;
  final String title;
  final String? description;
  final int groupId;
  final String groupName;
  final int createdBy;
  final String? creatorName;
  final DateTime startTime;
  final DateTime? endTime;
  final int participantCount;
  final int maxParticipants;
  final SessionStatus status;
  final List<SessionParticipant> participants;
  final List<SessionNote> sharedNotes;
  final String? topic;

  const CollaborativeSession({
    required this.id,
    required this.title,
    this.description,
    required this.groupId,
    required this.groupName,
    required this.createdBy,
    this.creatorName,
    required this.startTime,
    this.endTime,
    this.participantCount = 0,
    this.maxParticipants = 20,
    this.status = SessionStatus.scheduled,
    this.participants = const [],
    this.sharedNotes = const [],
    this.topic,
  });

  Duration? get duration =>
      endTime != null ? endTime!.difference(startTime) : null;

  bool get isActive => status == SessionStatus.active;

  @override
  List<Object?> get props => [id, title, groupId];
}

/// A participant in a collaborative session.
class SessionParticipant extends Equatable {
  final int userId;
  final String fullName;
  final String? profileImageUrl;
  final DateTime joinedAt;
  final bool isActive;

  const SessionParticipant({
    required this.userId,
    required this.fullName,
    this.profileImageUrl,
    required this.joinedAt,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [userId];
}

/// A shared note within a collaborative session.
class SessionNote extends Equatable {
  final int id;
  final int sessionId;
  final int authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const SessionNote({
    required this.id,
    required this.sessionId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, sessionId];
}

enum SessionStatus { scheduled, active, ended, cancelled }
