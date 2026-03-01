import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/forum.dart';

abstract class ForumRepository {
  Future<Either<Failure, List<Forum>>> getForumsByCourse(int courseId);
  Future<Either<Failure, List<ForumDiscussion>>> getDiscussions(int forumId);
  Future<Either<Failure, List<ForumPost>>> getDiscussionPosts(int discussionId);
  Future<Either<Failure, void>> addDiscussion(
    int forumId,
    String subject,
    String message,
  );
  Future<Either<Failure, void>> addReply(
    int postId,
    String subject,
    String message,
  );
  Future<Either<Failure, void>> togglePinDiscussion(
    int discussionId,
    bool pinned,
  );
  Future<Either<Failure, void>> deletePost(int postId);
}
