import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/social_entities.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/social_remote_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  final SocialRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SocialRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  Future<Either<Failure, T>> _guardedCall<T>(Future<T> Function() call) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final result = await call();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  // ═══════════════════════════════════════════
  //  Study Groups
  // ═══════════════════════════════════════════

  @override
  Future<Either<Failure, List<StudyGroup>>> getStudyGroups({int? courseId}) =>
      _guardedCall(() => remoteDataSource.getStudyGroups(courseId: courseId));

  @override
  Future<Either<Failure, StudyGroup>> getGroupDetail(int groupId) =>
      _guardedCall(() => remoteDataSource.getGroupDetail(groupId));

  @override
  Future<Either<Failure, StudyGroup>> createStudyGroup({
    required String name,
    required int courseId,
    String? description,
    bool isPublic = true,
    int maxMembers = 30,
  }) => _guardedCall(
    () => remoteDataSource.createStudyGroup(
      name: name,
      courseId: courseId,
      description: description,
      isPublic: isPublic,
      maxMembers: maxMembers,
    ),
  );

  @override
  Future<Either<Failure, void>> joinStudyGroup(int groupId) =>
      _guardedCall(() => remoteDataSource.joinStudyGroup(groupId));

  @override
  Future<Either<Failure, void>> leaveStudyGroup(int groupId) =>
      _guardedCall(() => remoteDataSource.leaveStudyGroup(groupId));

  @override
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(int groupId) =>
      _guardedCall(() => remoteDataSource.getGroupMembers(groupId));

  @override
  Future<Either<Failure, void>> updateGroupMemberRole(
    int groupId,
    int userId,
    GroupMemberRole role,
  ) => _guardedCall(
    () => remoteDataSource.updateGroupMemberRole(groupId, userId, role.name),
  );

  @override
  Future<Either<Failure, void>> deleteStudyGroup(int groupId) =>
      _guardedCall(() => remoteDataSource.deleteStudyGroup(groupId));

  // ═══════════════════════════════════════════
  //  Study Notes
  // ═══════════════════════════════════════════

  @override
  Future<Either<Failure, List<StudyNote>>> getCourseNotes(int courseId) =>
      _guardedCall(() => remoteDataSource.getCourseNotes(courseId));

  @override
  Future<Either<Failure, List<StudyNote>>> getGroupNotes(int groupId) =>
      _guardedCall(() => remoteDataSource.getGroupNotes(groupId));

  @override
  Future<Either<Failure, StudyNote>> createNote({
    required String title,
    required String content,
    required int courseId,
    int? groupId,
    NoteVisibility visibility = NoteVisibility.course,
    List<String> tags = const [],
  }) => _guardedCall(
    () => remoteDataSource.createNote(
      title: title,
      content: content,
      courseId: courseId,
      groupId: groupId,
      visibility: visibility.name,
      tags: tags,
    ),
  );

  @override
  Future<Either<Failure, StudyNote>> updateNote({
    required int noteId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) => _guardedCall(
    () => remoteDataSource.updateNote(
      noteId: noteId,
      title: title,
      content: content,
      tags: tags,
    ),
  );

  @override
  Future<Either<Failure, void>> deleteNote(int noteId) =>
      _guardedCall(() => remoteDataSource.deleteNote(noteId));

  @override
  Future<Either<Failure, void>> toggleLikeNote(int noteId) =>
      _guardedCall(() => remoteDataSource.toggleLikeNote(noteId));

  @override
  Future<Either<Failure, void>> toggleBookmarkNote(int noteId) =>
      _guardedCall(() => remoteDataSource.toggleBookmarkNote(noteId));

  @override
  Future<Either<Failure, List<NoteComment>>> getNoteComments(int noteId) =>
      _guardedCall(() => remoteDataSource.getNoteComments(noteId));

  @override
  Future<Either<Failure, NoteComment>> addNoteComment(
    int noteId,
    String content,
  ) => _guardedCall(() => remoteDataSource.addNoteComment(noteId, content));

  // ═══════════════════════════════════════════
  //  Peer Review
  // ═══════════════════════════════════════════

  @override
  Future<Either<Failure, List<PeerReview>>> getPendingReviews(int userId) =>
      _guardedCall(() => remoteDataSource.getPendingReviews(userId));

  @override
  Future<Either<Failure, List<PeerReview>>> getCompletedReviews(int userId) =>
      _guardedCall(() => remoteDataSource.getCompletedReviews(userId));

  @override
  Future<Either<Failure, PeerReview>> getReviewDetail(int reviewId) =>
      _guardedCall(() => remoteDataSource.getReviewDetail(reviewId));

  @override
  Future<Either<Failure, void>> submitReview({
    required int reviewId,
    required double rating,
    required String feedback,
  }) => _guardedCall(
    () => remoteDataSource.submitReview(
      reviewId: reviewId,
      rating: rating,
      feedback: feedback,
    ),
  );

  // ═══════════════════════════════════════════
  //  Collaborative Sessions
  // ═══════════════════════════════════════════

  @override
  Future<Either<Failure, List<CollaborativeSession>>> getGroupSessions(
    int groupId,
  ) => _guardedCall(() => remoteDataSource.getGroupSessions(groupId));

  @override
  Future<Either<Failure, CollaborativeSession>> createSession({
    required String title,
    required int groupId,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? topic,
  }) => _guardedCall(
    () => remoteDataSource.createSession(
      title: title,
      groupId: groupId,
      startTime: startTime,
      endTime: endTime,
      description: description,
      topic: topic,
    ),
  );

  @override
  Future<Either<Failure, void>> joinSession(int sessionId) =>
      _guardedCall(() => remoteDataSource.joinSession(sessionId));

  @override
  Future<Either<Failure, void>> leaveSession(int sessionId) =>
      _guardedCall(() => remoteDataSource.leaveSession(sessionId));

  @override
  Future<Either<Failure, void>> endSession(int sessionId) =>
      _guardedCall(() => remoteDataSource.endSession(sessionId));

  @override
  Future<Either<Failure, SessionNote>> addSessionNote(
    int sessionId,
    String content,
  ) => _guardedCall(() => remoteDataSource.addSessionNote(sessionId, content));
}
