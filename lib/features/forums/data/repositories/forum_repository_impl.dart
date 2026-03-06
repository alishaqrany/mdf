import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/forum.dart';
import '../../domain/repositories/forum_repository.dart';
import '../datasources/forum_remote_datasource.dart';

class ForumRepositoryImpl implements ForumRepository {
  final ForumRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ForumRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Forum>>> getForumsByCourse(int courseId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final forums = await remoteDataSource.getForumsByCourse(courseId);
      return Right(forums);
    } on MoodleException catch (e) {
      if (e.errorCode == 'accessexception') return const Right([]);
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on ServerException catch (e) {
      if (e.message.toLowerCase().contains('accessexception') ||
          e.errorCode == 'accessexception') {
        return const Right([]);
      }
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }

  @override
  Future<Either<Failure, List<ForumDiscussion>>> getDiscussions(
    int forumId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final discussions = await remoteDataSource.getDiscussions(forumId);
      return Right(discussions);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }

  @override
  Future<Either<Failure, List<ForumPost>>> getDiscussionPosts(
    int discussionId,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final posts = await remoteDataSource.getDiscussionPosts(discussionId);
      return Right(posts);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }

  @override
  Future<Either<Failure, void>> addDiscussion(
    int forumId,
    String subject,
    String message,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.addDiscussion(forumId, subject, message);
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }

  @override
  Future<Either<Failure, void>> addReply(
    int postId,
    String subject,
    String message,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.addReply(postId, subject, message);
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }

  @override
  Future<Either<Failure, void>> togglePinDiscussion(
    int discussionId,
    bool pinned,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.togglePinDiscussion(discussionId, pinned);
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(int postId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deletePost(postId);
      return const Right(null);
    } catch (e) {
      return Left(MdfErrorHandler.handleException(e, featureName: 'Forums'));
    }
  }
}
