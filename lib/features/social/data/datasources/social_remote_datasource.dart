import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/social_models.dart';

/// Remote datasource for social features.
/// Uses Moodle core_group, core_notes, and mod_workshop APIs,
/// plus custom local_mdf_api endpoints for extended social features.
abstract class SocialRemoteDataSource {
  // ─── Study Groups ───
  Future<List<StudyGroupModel>> getStudyGroups({int? courseId});
  Future<StudyGroupModel> getGroupDetail(int groupId);
  Future<StudyGroupModel> createStudyGroup({
    required String name,
    required int courseId,
    String? description,
    bool isPublic,
    int maxMembers,
  });
  Future<void> joinStudyGroup(int groupId);
  Future<void> leaveStudyGroup(int groupId);
  Future<List<GroupMemberModel>> getGroupMembers(int groupId);
  Future<void> updateGroupMemberRole(int groupId, int userId, String role);
  Future<void> deleteStudyGroup(int groupId);

  // ─── Study Notes ───
  Future<List<StudyNoteModel>> getCourseNotes(int courseId);
  Future<List<StudyNoteModel>> getGroupNotes(int groupId);
  Future<StudyNoteModel> createNote({
    required String title,
    required String content,
    required int courseId,
    int? groupId,
    String visibility,
    List<String> tags,
  });
  Future<StudyNoteModel> updateNote({
    required int noteId,
    required String title,
    required String content,
    List<String> tags,
  });
  Future<void> deleteNote(int noteId);
  Future<void> toggleLikeNote(int noteId);
  Future<void> toggleBookmarkNote(int noteId);
  Future<List<NoteCommentModel>> getNoteComments(int noteId);
  Future<NoteCommentModel> addNoteComment(int noteId, String content);

  // ─── Peer Review ───
  Future<List<PeerReviewModel>> getPendingReviews(int userId);
  Future<List<PeerReviewModel>> getCompletedReviews(int userId);
  Future<PeerReviewModel> getReviewDetail(int reviewId);
  Future<void> submitReview({
    required int reviewId,
    required double rating,
    required String feedback,
  });

  // ─── Collaborative Sessions ───
  Future<List<CollaborativeSessionModel>> getGroupSessions(int groupId);
  Future<CollaborativeSessionModel> createSession({
    required String title,
    required int groupId,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? topic,
  });
  Future<void> joinSession(int sessionId);
  Future<void> leaveSession(int sessionId);
  Future<void> endSession(int sessionId);
  Future<SessionNoteModel> addSessionNote(int sessionId, String content);
}

class SocialRemoteDataSourceImpl implements SocialRemoteDataSource {
  final MoodleApiClient apiClient;

  SocialRemoteDataSourceImpl({required this.apiClient});

  // ═══════════════════════════════════════════
  //  Study Groups — uses core_group + custom MDF API
  // ═══════════════════════════════════════════

  @override
  Future<List<StudyGroupModel>> getStudyGroups({int? courseId}) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetStudyGroups,
      params: {if (courseId != null) 'courseid': courseId},
    );

    if (response is List) {
      return response
          .map((j) => StudyGroupModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('groups')) {
      return (response['groups'] as List)
          .map((j) => StudyGroupModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<StudyGroupModel> getGroupDetail(int groupId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetStudyGroupDetail,
      params: {'groupid': groupId},
    );
    return StudyGroupModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<StudyGroupModel> createStudyGroup({
    required String name,
    required int courseId,
    String? description,
    bool isPublic = true,
    int maxMembers = 30,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfCreateStudyGroup,
      params: {
        'name': name,
        'courseid': courseId,
        if (description != null) 'description': description,
        'ispublic': isPublic ? 1 : 0,
        'maxmembers': maxMembers,
      },
    );
    return StudyGroupModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> joinStudyGroup(int groupId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfJoinStudyGroup,
      params: {'groupid': groupId},
    );
  }

  @override
  Future<void> leaveStudyGroup(int groupId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfLeaveStudyGroup,
      params: {'groupid': groupId},
    );
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers(int groupId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetGroupMembers,
      params: {'groupid': groupId},
    );

    if (response is List) {
      return response
          .map((j) => GroupMemberModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('members')) {
      return (response['members'] as List)
          .map((j) => GroupMemberModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> updateGroupMemberRole(
    int groupId,
    int userId,
    String role,
  ) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfUpdateGroupMemberRole,
      params: {'groupid': groupId, 'userid': userId, 'role': role},
    );
  }

  @override
  Future<void> deleteStudyGroup(int groupId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfDeleteStudyGroup,
      params: {'groupid': groupId},
    );
  }

  // ═══════════════════════════════════════════
  //  Study Notes — uses core_notes + custom MDF API
  // ═══════════════════════════════════════════

  @override
  Future<List<StudyNoteModel>> getCourseNotes(int courseId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCourseNotes,
      params: {'courseid': courseId},
    );

    if (response is List) {
      return response
          .map((j) => StudyNoteModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('notes')) {
      return (response['notes'] as List)
          .map((j) => StudyNoteModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<StudyNoteModel>> getGroupNotes(int groupId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetGroupNotes,
      params: {'groupid': groupId},
    );

    if (response is List) {
      return response
          .map((j) => StudyNoteModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<StudyNoteModel> createNote({
    required String title,
    required String content,
    required int courseId,
    int? groupId,
    String visibility = 'course',
    List<String> tags = const [],
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfCreateNote,
      params: {
        'title': title,
        'content': content,
        'courseid': courseId,
        if (groupId != null) 'groupid': groupId,
        'visibility': visibility,
        if (tags.isNotEmpty) 'tags': tags.join(','),
      },
    );
    return StudyNoteModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<StudyNoteModel> updateNote({
    required int noteId,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfUpdateNote,
      params: {
        'noteid': noteId,
        'title': title,
        'content': content,
        if (tags.isNotEmpty) 'tags': tags.join(','),
      },
    );
    return StudyNoteModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteNote(int noteId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfDeleteNote,
      params: {'noteid': noteId},
    );
  }

  @override
  Future<void> toggleLikeNote(int noteId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfToggleLikeNote,
      params: {'noteid': noteId},
    );
  }

  @override
  Future<void> toggleBookmarkNote(int noteId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfToggleBookmarkNote,
      params: {'noteid': noteId},
    );
  }

  @override
  Future<List<NoteCommentModel>> getNoteComments(int noteId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetNoteComments,
      params: {'noteid': noteId},
    );

    if (response is List) {
      return response
          .map((j) => NoteCommentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<NoteCommentModel> addNoteComment(int noteId, String content) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfAddNoteComment,
      params: {'noteid': noteId, 'content': content},
    );
    return NoteCommentModel.fromJson(response as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════
  //  Peer Review — uses mod_workshop API
  // ═══════════════════════════════════════════

  @override
  Future<List<PeerReviewModel>> getPendingReviews(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetPendingReviews,
      params: {'userid': userId},
    );

    if (response is List) {
      return response
          .map((j) => PeerReviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('reviews')) {
      return (response['reviews'] as List)
          .map((j) => PeerReviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<PeerReviewModel>> getCompletedReviews(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCompletedReviews,
      params: {'userid': userId},
    );

    if (response is List) {
      return response
          .map((j) => PeerReviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('reviews')) {
      return (response['reviews'] as List)
          .map((j) => PeerReviewModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<PeerReviewModel> getReviewDetail(int reviewId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetReviewDetail,
      params: {'reviewid': reviewId},
    );
    return PeerReviewModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> submitReview({
    required int reviewId,
    required double rating,
    required String feedback,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfSubmitReview,
      params: {'reviewid': reviewId, 'rating': rating, 'feedback': feedback},
    );
  }

  // ═══════════════════════════════════════════
  //  Collaborative Sessions — custom MDF API
  // ═══════════════════════════════════════════

  @override
  Future<List<CollaborativeSessionModel>> getGroupSessions(int groupId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetGroupSessions,
      params: {'groupid': groupId},
    );

    if (response is List) {
      return response
          .map(
            (j) =>
                CollaborativeSessionModel.fromJson(j as Map<String, dynamic>),
          )
          .toList();
    }
    if (response is Map && response.containsKey('sessions')) {
      return (response['sessions'] as List)
          .map(
            (j) =>
                CollaborativeSessionModel.fromJson(j as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  @override
  Future<CollaborativeSessionModel> createSession({
    required String title,
    required int groupId,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    String? topic,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfCreateSession,
      params: {
        'title': title,
        'groupid': groupId,
        'starttime': startTime.millisecondsSinceEpoch ~/ 1000,
        if (endTime != null) 'endtime': endTime.millisecondsSinceEpoch ~/ 1000,
        if (description != null) 'description': description,
        if (topic != null) 'topic': topic,
      },
    );
    return CollaborativeSessionModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> joinSession(int sessionId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfJoinSession,
      params: {'sessionid': sessionId},
    );
  }

  @override
  Future<void> leaveSession(int sessionId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfLeaveSession,
      params: {'sessionid': sessionId},
    );
  }

  @override
  Future<void> endSession(int sessionId) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfEndSession,
      params: {'sessionid': sessionId},
    );
  }

  @override
  Future<SessionNoteModel> addSessionNote(int sessionId, String content) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfAddSessionNote,
      params: {'sessionid': sessionId, 'content': content},
    );
    return SessionNoteModel.fromJson(response as Map<String, dynamic>);
  }
}
