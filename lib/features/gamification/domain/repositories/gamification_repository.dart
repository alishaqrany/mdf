import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/gamification_entities.dart';

/// Abstract repository for all gamification features.
abstract class GamificationRepository {
  // ─── Points & XP ───
  Future<Either<Failure, UserPoints>> getUserPoints(int userId);
  Future<Either<Failure, List<PointTransaction>>> getPointHistory(
    int userId, {
    int page = 0,
    int limit = 20,
  });
  Future<Either<Failure, UserPoints>> awardPoints({
    required int userId,
    required int points,
    required PointAction action,
    required String description,
    int? referenceId,
  });

  // ─── Badges ───
  Future<Either<Failure, List<Badge>>> getAllBadges(int userId);
  Future<Either<Failure, List<Badge>>> getEarnedBadges(int userId);
  Future<Either<Failure, Badge>> getBadgeDetail(int badgeId, int userId);

  // ─── Leaderboard ───
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    required LeaderboardPeriod period,
    int? courseId,
    int limit = 50,
  });

  // ─── Challenges ───
  Future<Either<Failure, List<Challenge>>> getActiveChallenges(int userId);
  Future<Either<Failure, List<Challenge>>> getCompletedChallenges(int userId);
  Future<Either<Failure, Challenge>> claimChallengeReward(
    int challengeId,
    int userId,
  );

  // ─── Streaks ───
  Future<Either<Failure, UserPoints>> recordDailyLogin(int userId);
}
