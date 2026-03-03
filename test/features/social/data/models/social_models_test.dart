import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/social/data/models/social_models.dart';
import 'package:mdf_app/features/social/domain/entities/social_entities.dart';

void main() {
  // ───────────────────── StudyGroupModel ─────────────────────
  group('StudyGroupModel.fromJson', () {
    test('should parse all fields with members', () {
      final model = StudyGroupModel.fromJson(const {
        'id': 1,
        'name': 'Math Study Group',
        'description': 'Study together',
        'courseid': 101,
        'coursename': 'Mathematics 101',
        'createdby': 42,
        'creatorname': 'Alice',
        'imageurl': 'https://img.com/group.png',
        'ispublic': 1,
        'membercount': 5,
        'maxmembers': 20,
        'timecreated': 1700000000,
        'userrole': 'admin',
        'members': [
          {
            'userid': 42,
            'fullname': 'Alice',
            'role': 'admin',
            'timejoined': 1700000000,
          },
        ],
      });
      expect(model.id, 1);
      expect(model.name, 'Math Study Group');
      expect(model.description, 'Study together');
      expect(model.courseId, 101);
      expect(model.courseName, 'Mathematics 101');
      expect(model.createdBy, 42);
      expect(model.creatorName, 'Alice');
      expect(model.isPublic, true);
      expect(model.memberCount, 5);
      expect(model.maxMembers, 20);
      expect(
        model.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      expect(model.currentUserRole, GroupMemberRole.admin);
      expect(model.members, hasLength(1));
      expect(model.members[0].fullName, 'Alice');
    });

    test('should handle ispublic=0 as false', () {
      final model = StudyGroupModel.fromJson(const {
        'id': 1,
        'name': 'x',
        'courseid': 1,
        'createdby': 1,
        'timecreated': 0,
        'ispublic': 0,
      });
      expect(model.isPublic, false);
    });

    test('should handle null userrole', () {
      final model = StudyGroupModel.fromJson(const {
        'id': 1,
        'name': 'x',
        'courseid': 1,
        'createdby': 1,
        'timecreated': 0,
      });
      expect(model.currentUserRole, isNull);
    });

    test('should parse all member roles', () {
      for (final role in ['admin', 'moderator', 'member']) {
        final model = StudyGroupModel.fromJson({
          'id': 1,
          'name': 'x',
          'courseid': 1,
          'createdby': 1,
          'timecreated': 0,
          'userrole': role,
        });
        expect(model.currentUserRole, isNotNull, reason: 'Failed for $role');
      }
    });

    test('should default members to empty when null', () {
      final model = StudyGroupModel.fromJson(const {
        'id': 1,
        'name': 'x',
        'courseid': 1,
        'createdby': 1,
        'timecreated': 0,
      });
      expect(model.members, isEmpty);
    });
  });

  // ───────────────────── GroupMemberModel ─────────────────────
  group('GroupMemberModel.fromJson', () {
    test('should parse with userid key', () {
      final model = GroupMemberModel.fromJson(const {
        'userid': 10,
        'fullname': 'Bob',
        'profileimageurl': 'https://img.com/bob.png',
        'role': 'moderator',
        'timejoined': 1700000000,
        'isonline': true,
      });
      expect(model.userId, 10);
      expect(model.fullName, 'Bob');
      expect(model.role, GroupMemberRole.moderator);
      expect(model.isOnline, true);
    });

    test('should fallback to id key when userid is null', () {
      final model = GroupMemberModel.fromJson(const {
        'id': 20,
        'fullname': 'Charlie',
        'timejoined': 0,
      });
      expect(model.userId, 20);
    });

    test('should default role to member', () {
      final model = GroupMemberModel.fromJson(const {
        'userid': 1,
        'fullname': 'x',
        'timejoined': 0,
      });
      expect(model.role, GroupMemberRole.member);
    });
  });

  // ───────────────────── StudyNoteModel ─────────────────────
  group('StudyNoteModel.fromJson', () {
    test('should parse all fields', () {
      final model = StudyNoteModel.fromJson(const {
        'id': 1,
        'title': 'Chapter 1 Notes',
        'content': 'Key concepts...',
        'userid': 42,
        'userfullname': 'Alice',
        'userprofileimageurl': 'https://img.com/alice.png',
        'courseid': 101,
        'coursename': 'Math 101',
        'modulename': 'quiz',
        'likes': 5,
        'isliked': true,
        'isbookmarked': false,
        'commentcount': 3,
        'visibility': 'public',
        'tags': ['math', 'chapter1'],
        'timecreated': 1700000000,
        'timemodified': 1700100000,
      });
      expect(model.id, 1);
      expect(model.title, 'Chapter 1 Notes');
      expect(model.content, 'Key concepts...');
      expect(model.authorId, 42);
      expect(model.authorName, 'Alice');
      expect(model.courseId, 101);
      expect(model.likes, 5);
      expect(model.isLiked, true);
      expect(model.isBookmarked, false);
      expect(model.commentCount, 3);
      expect(model.visibility, NoteVisibility.public);
      expect(model.tags, ['math', 'chapter1']);
    });

    test('should fall back to publishstate for title', () {
      final model = StudyNoteModel.fromJson(const {
        'id': 1,
        'publishstate': 'Draft',
        'content': '',
        'userid': 1,
        'userfullname': '',
        'courseid': 1,
        'timecreated': 0,
        'timemodified': 0,
      });
      expect(model.title, 'Draft');
    });

    test('should parse all visibility values', () {
      final vis = {
        'personal': NoteVisibility.personal,
        'group': NoteVisibility.group,
        'course': NoteVisibility.course,
        'public': NoteVisibility.public,
      };
      for (final entry in vis.entries) {
        final model = StudyNoteModel.fromJson({
          'id': 1,
          'content': '',
          'userid': 1,
          'userfullname': '',
          'courseid': 1,
          'timecreated': 0,
          'timemodified': 0,
          'visibility': entry.key,
        });
        expect(model.visibility, entry.value);
      }
    });

    test('should default visibility to course', () {
      final model = StudyNoteModel.fromJson(const {
        'id': 1,
        'content': '',
        'userid': 1,
        'userfullname': '',
        'courseid': 1,
        'timecreated': 0,
        'timemodified': 0,
      });
      expect(model.visibility, NoteVisibility.course);
    });

    test('should default tags to empty when null', () {
      final model = StudyNoteModel.fromJson(const {
        'id': 1,
        'content': '',
        'userid': 1,
        'userfullname': '',
        'courseid': 1,
        'timecreated': 0,
        'timemodified': 0,
      });
      expect(model.tags, isEmpty);
    });
  });

  // ───────────────────── NoteCommentModel ─────────────────────
  group('NoteCommentModel.fromJson', () {
    test('should parse all fields', () {
      final model = NoteCommentModel.fromJson(const {
        'id': 1,
        'noteid': 10,
        'userid': 42,
        'userfullname': 'Alice',
        'userprofileimageurl': 'https://img.com/alice.png',
        'content': 'Great notes!',
        'timecreated': 1700000000,
      });
      expect(model.id, 1);
      expect(model.noteId, 10);
      expect(model.authorId, 42);
      expect(model.authorName, 'Alice');
      expect(model.authorImageUrl, 'https://img.com/alice.png');
      expect(model.content, 'Great notes!');
    });

    test('should default missing fields', () {
      final model = NoteCommentModel.fromJson(const {});
      expect(model.id, 0);
      expect(model.noteId, 0);
      expect(model.authorName, '');
      expect(model.content, '');
    });
  });

  // ───────────────────── PeerReviewModel ─────────────────────
  group('PeerReviewModel.fromJson', () {
    test('should parse all fields', () {
      final model = PeerReviewModel.fromJson(const {
        'id': 1,
        'workshopid': 10,
        'workshopname': 'Peer Workshop 1',
        'courseid': 101,
        'coursename': 'Math 101',
        'authorid': 42,
        'authorfullname': 'Alice',
        'authorprofileimageurl': 'https://img.com/alice.png',
        'reviewerid': 43,
        'reviewerfullname': 'Bob',
        'grade': 85.5,
        'maxgrade': 100.0,
        'feedbackauthor': 'Good work!',
        'status': 'completed',
        'timesubmitted': 1700000000,
        'timereviewed': 1700500000,
        'content': 'My submission content',
        'attachments': ['file1.pdf', 'file2.pdf'],
      });
      expect(model.id, 1);
      expect(model.workshopId, 10);
      expect(model.workshopName, 'Peer Workshop 1');
      expect(model.courseId, 101);
      expect(model.submitterId, 42);
      expect(model.submitterName, 'Alice');
      expect(model.reviewerId, 43);
      expect(model.reviewerName, 'Bob');
      expect(model.rating, 85.5);
      expect(model.maxRating, 100.0);
      expect(model.feedback, 'Good work!');
      expect(model.status, PeerReviewStatus.completed);
      expect(model.submissionContent, 'My submission content');
      expect(model.submissionAttachments, ['file1.pdf', 'file2.pdf']);
    });

    test('should fall back to assessmentid', () {
      final model = PeerReviewModel.fromJson(const {
        'assessmentid': 99,
        'workshopid': 1,
        'workshopname': 'x',
        'courseid': 1,
        'authorid': 1,
        'authorfullname': 'x',
      });
      expect(model.id, 99);
    });

    test('should parse all statuses', () {
      final statuses = {
        'pending': PeerReviewStatus.pending,
        'inprogress': PeerReviewStatus.inProgress,
        'completed': PeerReviewStatus.completed,
        'overdue': PeerReviewStatus.overdue,
      };
      for (final entry in statuses.entries) {
        final model = PeerReviewModel.fromJson({
          'id': 1,
          'workshopid': 1,
          'workshopname': 'x',
          'courseid': 1,
          'authorid': 1,
          'authorfullname': 'x',
          'status': entry.key,
        });
        expect(model.status, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('should default attachments to empty', () {
      final model = PeerReviewModel.fromJson(const {
        'id': 1,
        'workshopid': 1,
        'workshopname': 'x',
        'courseid': 1,
        'authorid': 1,
        'authorfullname': 'x',
      });
      expect(model.submissionAttachments, isEmpty);
    });
  });

  // ───────────────────── CollaborativeSessionModel ─────────────────────
  group('CollaborativeSessionModel.fromJson', () {
    test('should parse all fields with participants and notes', () {
      final model = CollaborativeSessionModel.fromJson(const {
        'id': 1,
        'title': 'Study Session',
        'description': 'Math review',
        'groupid': 5,
        'groupname': 'Math Group',
        'createdby': 42,
        'creatorname': 'Alice',
        'starttime': 1700000000,
        'endtime': 1700003600,
        'participantcount': 3,
        'maxparticipants': 10,
        'status': 'active',
        'topic': 'Chapter 5',
        'participants': [
          {
            'userid': 42,
            'fullname': 'Alice',
            'timejoined': 1700000000,
            'isactive': true,
          },
        ],
        'notes': [
          {
            'id': 1,
            'sessionid': 1,
            'userid': 42,
            'userfullname': 'Alice',
            'content': 'Key formula...',
            'timecreated': 1700001000,
          },
        ],
      });
      expect(model.id, 1);
      expect(model.title, 'Study Session');
      expect(model.groupId, 5);
      expect(model.groupName, 'Math Group');
      expect(model.status, SessionStatus.active);
      expect(model.topic, 'Chapter 5');
      expect(model.participants, hasLength(1));
      expect(model.participants[0].fullName, 'Alice');
      expect(model.sharedNotes, hasLength(1));
      expect(model.sharedNotes[0].content, 'Key formula...');
    });

    test('should parse all session statuses', () {
      final statuses = {
        'scheduled': SessionStatus.scheduled,
        'active': SessionStatus.active,
        'ended': SessionStatus.ended,
        'cancelled': SessionStatus.cancelled,
      };
      for (final entry in statuses.entries) {
        final model = CollaborativeSessionModel.fromJson({
          'id': 1,
          'title': 'x',
          'groupid': 1,
          'groupname': 'x',
          'createdby': 1,
          'starttime': 0,
          'status': entry.key,
        });
        expect(model.status, entry.value);
      }
    });

    test('should default participants and notes to empty', () {
      final model = CollaborativeSessionModel.fromJson(const {
        'id': 1,
        'title': 'x',
        'groupid': 1,
        'groupname': 'x',
        'createdby': 1,
        'starttime': 0,
      });
      expect(model.participants, isEmpty);
      expect(model.sharedNotes, isEmpty);
    });

    test('should handle null endtime', () {
      final model = CollaborativeSessionModel.fromJson(const {
        'id': 1,
        'title': 'x',
        'groupid': 1,
        'groupname': 'x',
        'createdby': 1,
        'starttime': 0,
      });
      expect(model.endTime, isNull);
    });
  });

  // ───────────────────── SessionParticipantModel ─────────────────────
  group('SessionParticipantModel.fromJson', () {
    test('should parse all fields', () {
      final model = SessionParticipantModel.fromJson(const {
        'userid': 42,
        'fullname': 'Alice',
        'profileimageurl': 'https://img.com/alice.png',
        'timejoined': 1700000000,
        'isactive': false,
      });
      expect(model.userId, 42);
      expect(model.fullName, 'Alice');
      expect(model.isActive, false);
    });

    test('should default isactive to true', () {
      final model = SessionParticipantModel.fromJson(const {
        'userid': 1,
        'fullname': 'x',
        'timejoined': 0,
      });
      expect(model.isActive, true);
    });
  });

  // ───────────────────── SessionNoteModel ─────────────────────
  group('SessionNoteModel.fromJson', () {
    test('should parse all fields', () {
      final model = SessionNoteModel.fromJson(const {
        'id': 1,
        'sessionid': 10,
        'userid': 42,
        'userfullname': 'Alice',
        'content': 'Important note',
        'timecreated': 1700000000,
      });
      expect(model.id, 1);
      expect(model.sessionId, 10);
      expect(model.authorId, 42);
      expect(model.authorName, 'Alice');
      expect(model.content, 'Important note');
    });

    test('should default missing fields', () {
      final model = SessionNoteModel.fromJson(const {});
      expect(model.id, 0);
      expect(model.sessionId, 0);
      expect(model.authorName, '');
      expect(model.content, '');
    });
  });
}
