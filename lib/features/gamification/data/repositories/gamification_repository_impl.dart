import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/gamification_entities.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_datasource.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GamificationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  Future<Either<Failure, T>> _guardedCall<T>(
    Future<T> Function() call,
  ) async {
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

  // ─── Points & XP ───

  @override
  Future<Either<Failure, UserPoints>> getUserPoints(int userId) =>
      _guardedCall(() => remoteDataSource.getUserPoints(userId));

  @override
  Future<Either<Failure, List<PointTransaction>>> getPointHistory(
    int userId, {
    int page = 0,
    int limit = 20,
  }) =>
      _guardedCall(
        () => remoteDataSource.getPointHistory(userId,
            page: page, limit: limit),
      );

  @override
  Future<Either<Failure, UserPoints>> awardPoints({
    required int userId,
    required int points,
    required PointAction action,
    required String description,
    int? referenceId,
  }) =>
      _guardedCall(
        () => remoteDataSource.awardPoints(
          userId: userId,
          points: points,
          action: action.name,
          description: description,
          referenceId: referenceId,
        ),
      );

  // ─── Badges ───

  @override
  Future<Either<Failure, List<Badge>>> getAllBadges(int userId) =>
      _guardedCall(() => remoteDataSource.getAllBadges(userId));

  @override
  Future<Either<Failure, List<Badge>>> getEarnedBadges(int userId) =>
      _guardedCall(() => remoteDataSource.getEarnedBadges(userId));

  @override
  Future<Either<Failure, Badge>> getBadgeDetail(int badgeId, int userId) =>
      _guardedCall(() => remoteDataSource.getBadgeDetail(badgeId, userId));

  // ─── Leaderboard ───

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    required LeaderboardPeriod period,
    int? courseId,
    int limit = 50,
  }) =>
      _guardedCall(
        () => remoteDataSource.getLeaderboard(
          period: period.name,
          courseId: courseId,
          limit: limit,
        ),
      );

  // ─── Challenges ───

  @override
  Future<Either<Failure, List<Challenge>>> getActiveChallenges(int userId) =>
      _guardedCall(() => remoteDataSource.getActiveChallenges(userId));

  @override
  Future<Either<Failure, List<Challenge>>> getCompletedChallenges(
    int userId,
  ) =>
      _guardedCall(() => remoteDataSource.getCompletedChallenges(userId));

  @override
  Future<Either<Failure, Challenge>> claimChallengeReward(
    int challengeId,
    int userId,
  ) =>
      _guardedCall(
        () => remoteDataSource.claimChallengeReward(challengeId, userId),
      );

  // ─── Streaks ───

  @override
  Future<Either<Failure, UserPoints>> recordDailyLogin(int userId) =>
      _guardedCall(() => remoteDataSource.recordDailyLogin(userId));
}
