import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/forum_model.dart';

abstract class ForumRemoteDataSource {
  Future<List<ForumModel>> getForumsByCourse(int courseId);
  Future<List<ForumDiscussionModel>> getDiscussions(int forumId);
  Future<List<ForumPostModel>> getDiscussionPosts(int discussionId);
  Future<void> addDiscussion(int forumId, String subject, String message);
  Future<void> addReply(int postId, String subject, String message);
  Future<void> togglePinDiscussion(int discussionId, bool pinned);
  Future<void> deletePost(int postId);
}

class ForumRemoteDataSourceImpl implements ForumRemoteDataSource {
  final MoodleApiClient apiClient;

  ForumRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ForumModel>> getForumsByCourse(int courseId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getForums,
      params: {'courseids[0]': courseId},
    );

    if (response is List) {
      return response
          .map((j) => ForumModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ForumDiscussionModel>> getDiscussions(int forumId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getForumDiscussions,
      params: {'forumid': forumId},
    );

    if (response is Map && response.containsKey('discussions')) {
      return (response['discussions'] as List)
          .map((j) => ForumDiscussionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ForumPostModel>> getDiscussionPosts(int discussionId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getDiscussionPosts,
      params: {'discussionid': discussionId},
    );

    if (response is Map && response.containsKey('posts')) {
      return (response['posts'] as List)
          .map((j) => ForumPostModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> addDiscussion(
    int forumId,
    String subject,
    String message,
  ) async {
    await apiClient.call(
      MoodleApiEndpoints.addDiscussion,
      params: {'forumid': forumId, 'subject': subject, 'message': message},
    );
  }

  @override
  Future<void> addReply(int postId, String subject, String message) async {
    await apiClient.call(
      MoodleApiEndpoints.addDiscussionPost,
      params: {'postid': postId, 'subject': subject, 'message': message},
    );
  }

  @override
  Future<void> togglePinDiscussion(int discussionId, bool pinned) async {
    await apiClient.call(
      MoodleApiEndpoints.setPinState,
      params: {'discussionid': discussionId, 'targetstate': pinned ? 1 : 0},
    );
  }

  @override
  Future<void> deletePost(int postId) async {
    await apiClient.call(
      MoodleApiEndpoints.deletePost,
      params: {'postid': postId},
    );
  }
}
