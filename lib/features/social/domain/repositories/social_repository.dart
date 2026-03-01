import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/social_entities.dart';

/// Abstract repository for all social/collaborative learning features.
abstract class SocialRepository {
  // ─── Study Groups ───
  Future<Either<Failure, List<StudyGroup>>> getStudyGroups({int? courseId});
  Future<Either<Failure, StudyGroup>> getGroupDetail(int groupId);
  Future<Either<Failure, StudyGroup>> createStudyGroup({
    required String name,
    required int courseId,
    String? description,
    bool isPublic = true,
    int maxMembers = 30,
  });
  Future<Either<Failure, void>> joinStudyGroup(int groupId);
  Future<Either<Failure, void>> leaveStudyGroup(int groupId);
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(int groupId);
  Future<Either<Failure, void>> updateGroupMemberRole(
    int groupId,
    int userId,
    GroupMemberRole role,
  );
  Future<Either<Failure, void>> deleteStudyGroup(int groupId);

  // ─── Study Notes ───
  Future<Either<Failure, List<StudyNote>>> getCourseNotes(int courseId);
  Future<Either<Failure, List<StudyNote>>> getGroupNotes(int groupId);
  Future<Either<Failure, StudyNote>> createNote({
    required String title,
    required String content,
    required int courseId,
    int? groupId,
    NoteVisibility visibility = NoteVisibility.course,
    List<String> tags = const [],
  });
  Future<Either<Failure, StudyNote>> updateNote({
    required int noteId,
    required String title,
    required String content,
    List<String> tags = const [],
  });
  Future<Either<Failure, void>> deleteNote(int noteId);
  Future<Either<Failure, void>> toggleLikeNote(int noteId);
  Future<Either<Failure, void>> toggleBookmarkNote(int noteId);
  Future<Either<Failure, List<NoteComment>>> getNoteComments(int noteId);
  Future<Either<Failure, NoteComment>> addNoteComment(
    int noteId,
    String content,
  );

  // ─── Peer Review ───
  Future<Either<Failure, List<PeerReview>>> getPendingReviews(int userId);
  Future<Either<Failure, List<PeerReview>>> getCompletedReviews(int userId);
  Future<Either<Failure, PeerReview>> getReviewDetail(int reviewId);
  Future<Either<Failure, void>> submitReview({
    required int reviewId,
    required double rating,
    required String feedback,
  });

  // ─── Collaborative Sessions ───
  Future<Either<Failure, List<CollaborativeSession>>> getGroupSessions(
    int groupId,
  );
  Future<Either<Failure, CollaborativeSession>> createSession({
    required String title,
    required int groupId,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? topic,
  });
  Future<Either<Failure, void>> joinSession(int sessionId);
  Future<Either<Failure, void>> leaveSession(int sessionId);
  Future<Either<Failure, void>> endSession(int sessionId);
  Future<Either<Failure, SessionNote>> addSessionNote(
    int sessionId,
    String content,
  );
}
