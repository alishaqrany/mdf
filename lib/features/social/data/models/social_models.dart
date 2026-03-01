import '../../domain/entities/social_entities.dart';

// ─────────────────────────────────────────────
//  Study Group Model
// ─────────────────────────────────────────────

class StudyGroupModel extends StudyGroup {
  const StudyGroupModel({
    required super.id,
    required super.name,
    super.description,
    required super.courseId,
    super.courseName,
    required super.createdBy,
    super.creatorName,
    super.imageUrl,
    super.isPublic,
    super.memberCount,
    super.maxMembers,
    required super.createdAt,
    super.members,
    super.currentUserRole,
  });

  factory StudyGroupModel.fromJson(Map<String, dynamic> json) {
    return StudyGroupModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      courseId: json['courseid'] as int? ?? 0,
      courseName: json['coursename'] as String?,
      createdBy: json['createdby'] as int? ?? 0,
      creatorName: json['creatorname'] as String?,
      imageUrl: json['imageurl'] as String?,
      isPublic: (json['ispublic'] as int? ?? 1) == 1,
      memberCount: json['membercount'] as int? ?? 0,
      maxMembers: json['maxmembers'] as int? ?? 30,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timecreated'] as int?) ?? 0) * 1000,
      ),
      currentUserRole: _parseRole(json['userrole'] as String?),
      members: json['members'] != null
          ? (json['members'] as List)
                .map(
                  (m) => GroupMemberModel.fromJson(m as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }

  static GroupMemberRole? _parseRole(String? role) {
    switch (role) {
      case 'admin':
        return GroupMemberRole.admin;
      case 'moderator':
        return GroupMemberRole.moderator;
      case 'member':
        return GroupMemberRole.member;
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────
//  Group Member Model
// ─────────────────────────────────────────────

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.userId,
    required super.fullName,
    super.profileImageUrl,
    super.role,
    required super.joinedAt,
    super.isOnline,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userid'] as int? ?? json['id'] as int? ?? 0,
      fullName: json['fullname'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      role:
          StudyGroupModel._parseRole(json['role'] as String?) ??
          GroupMemberRole.member,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timejoined'] as int?) ?? 0) * 1000,
      ),
      isOnline: (json['isonline'] as bool?) ?? false,
    );
  }
}

// ─────────────────────────────────────────────
//  Study Note Model
// ─────────────────────────────────────────────

class StudyNoteModel extends StudyNote {
  const StudyNoteModel({
    required super.id,
    required super.title,
    required super.content,
    required super.authorId,
    required super.authorName,
    super.authorImageUrl,
    required super.courseId,
    super.courseName,
    super.moduleName,
    super.likes,
    super.isLiked,
    super.isBookmarked,
    super.commentCount,
    super.visibility,
    super.tags,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StudyNoteModel.fromJson(Map<String, dynamic> json) {
    return StudyNoteModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['publishstate'] as String? ?? '',
      content: json['content'] as String? ?? '',
      authorId: json['userid'] as int? ?? 0,
      authorName: json['userfullname'] as String? ?? '',
      authorImageUrl: json['userprofileimageurl'] as String?,
      courseId: json['courseid'] as int? ?? 0,
      courseName: json['coursename'] as String?,
      moduleName: json['modulename'] as String?,
      likes: json['likes'] as int? ?? 0,
      isLiked: (json['isliked'] as bool?) ?? false,
      isBookmarked: (json['isbookmarked'] as bool?) ?? false,
      commentCount: json['commentcount'] as int? ?? 0,
      visibility: _parseVisibility(json['visibility'] as String?),
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timecreated'] as int?) ?? 0) * 1000,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timemodified'] as int?) ?? 0) * 1000,
      ),
    );
  }

  static NoteVisibility _parseVisibility(String? v) {
    switch (v) {
      case 'personal':
        return NoteVisibility.personal;
      case 'group':
        return NoteVisibility.group;
      case 'course':
        return NoteVisibility.course;
      case 'public':
        return NoteVisibility.public;
      default:
        return NoteVisibility.course;
    }
  }
}

// ─────────────────────────────────────────────
//  Note Comment Model
// ─────────────────────────────────────────────

class NoteCommentModel extends NoteComment {
  const NoteCommentModel({
    required super.id,
    required super.noteId,
    required super.authorId,
    required super.authorName,
    super.authorImageUrl,
    required super.content,
    required super.createdAt,
  });

  factory NoteCommentModel.fromJson(Map<String, dynamic> json) {
    return NoteCommentModel(
      id: json['id'] as int? ?? 0,
      noteId: json['noteid'] as int? ?? 0,
      authorId: json['userid'] as int? ?? 0,
      authorName: json['userfullname'] as String? ?? '',
      authorImageUrl: json['userprofileimageurl'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timecreated'] as int?) ?? 0) * 1000,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Peer Review Model
// ─────────────────────────────────────────────

class PeerReviewModel extends PeerReview {
  const PeerReviewModel({
    required super.id,
    required super.workshopId,
    required super.workshopName,
    required super.courseId,
    super.courseName,
    required super.submitterId,
    required super.submitterName,
    super.submitterImageUrl,
    super.reviewerId,
    super.reviewerName,
    super.rating,
    super.maxRating,
    super.feedback,
    super.status,
    super.submittedAt,
    super.reviewedAt,
    super.submissionContent,
    super.submissionAttachments,
  });

  factory PeerReviewModel.fromJson(Map<String, dynamic> json) {
    return PeerReviewModel(
      id: json['id'] as int? ?? json['assessmentid'] as int? ?? 0,
      workshopId: json['workshopid'] as int? ?? 0,
      workshopName: json['workshopname'] as String? ?? '',
      courseId: json['courseid'] as int? ?? 0,
      courseName: json['coursename'] as String?,
      submitterId: json['authorid'] as int? ?? 0,
      submitterName: json['authorfullname'] as String? ?? '',
      submitterImageUrl: json['authorprofileimageurl'] as String?,
      reviewerId: json['reviewerid'] as int?,
      reviewerName: json['reviewerfullname'] as String?,
      rating: (json['grade'] as num?)?.toDouble(),
      maxRating: (json['maxgrade'] as num?)?.toDouble() ?? 100,
      feedback: json['feedbackauthor'] as String?,
      status: _parseStatus(json['status'] as String?),
      submittedAt: json['timesubmitted'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timesubmitted'] as int) * 1000,
            )
          : null,
      reviewedAt: json['timereviewed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timereviewed'] as int) * 1000,
            )
          : null,
      submissionContent: json['content'] as String?,
      submissionAttachments: json['attachments'] != null
          ? List<String>.from(json['attachments'] as List)
          : const [],
    );
  }

  static PeerReviewStatus _parseStatus(String? s) {
    switch (s) {
      case 'inprogress':
        return PeerReviewStatus.inProgress;
      case 'completed':
        return PeerReviewStatus.completed;
      case 'overdue':
        return PeerReviewStatus.overdue;
      default:
        return PeerReviewStatus.pending;
    }
  }
}

// ─────────────────────────────────────────────
//  Collaborative Session Model
// ─────────────────────────────────────────────

class CollaborativeSessionModel extends CollaborativeSession {
  const CollaborativeSessionModel({
    required super.id,
    required super.title,
    super.description,
    required super.groupId,
    required super.groupName,
    required super.createdBy,
    super.creatorName,
    required super.startTime,
    super.endTime,
    super.participantCount,
    super.maxParticipants,
    super.status,
    super.participants,
    super.sharedNotes,
    super.topic,
  });

  factory CollaborativeSessionModel.fromJson(Map<String, dynamic> json) {
    return CollaborativeSessionModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      groupId: json['groupid'] as int? ?? 0,
      groupName: json['groupname'] as String? ?? '',
      createdBy: json['createdby'] as int? ?? 0,
      creatorName: json['creatorname'] as String?,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        ((json['starttime'] as int?) ?? 0) * 1000,
      ),
      endTime: json['endtime'] != null
          ? DateTime.fromMillisecondsSinceEpoch((json['endtime'] as int) * 1000)
          : null,
      participantCount: json['participantcount'] as int? ?? 0,
      maxParticipants: json['maxparticipants'] as int? ?? 20,
      status: _parseSessionStatus(json['status'] as String?),
      topic: json['topic'] as String?,
      participants: json['participants'] != null
          ? (json['participants'] as List)
                .map(
                  (p) => SessionParticipantModel.fromJson(
                    p as Map<String, dynamic>,
                  ),
                )
                .toList()
          : const [],
      sharedNotes: json['notes'] != null
          ? (json['notes'] as List)
                .map(
                  (n) => SessionNoteModel.fromJson(n as Map<String, dynamic>),
                )
                .toList()
          : const [],
    );
  }

  static SessionStatus _parseSessionStatus(String? s) {
    switch (s) {
      case 'active':
        return SessionStatus.active;
      case 'ended':
        return SessionStatus.ended;
      case 'cancelled':
        return SessionStatus.cancelled;
      default:
        return SessionStatus.scheduled;
    }
  }
}

class SessionParticipantModel extends SessionParticipant {
  const SessionParticipantModel({
    required super.userId,
    required super.fullName,
    super.profileImageUrl,
    required super.joinedAt,
    super.isActive,
  });

  factory SessionParticipantModel.fromJson(Map<String, dynamic> json) {
    return SessionParticipantModel(
      userId: json['userid'] as int? ?? 0,
      fullName: json['fullname'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timejoined'] as int?) ?? 0) * 1000,
      ),
      isActive: (json['isactive'] as bool?) ?? true,
    );
  }
}

class SessionNoteModel extends SessionNote {
  const SessionNoteModel({
    required super.id,
    required super.sessionId,
    required super.authorId,
    required super.authorName,
    required super.content,
    required super.createdAt,
  });

  factory SessionNoteModel.fromJson(Map<String, dynamic> json) {
    return SessionNoteModel(
      id: json['id'] as int? ?? 0,
      sessionId: json['sessionid'] as int? ?? 0,
      authorId: json['userid'] as int? ?? 0,
      authorName: json['userfullname'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timecreated'] as int?) ?? 0) * 1000,
      ),
    );
  }
}
