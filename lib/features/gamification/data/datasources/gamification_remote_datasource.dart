import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/gamification_models.dart';

/// Remote datasource for gamification features.
abstract class GamificationRemoteDataSource {
  Future<UserPointsModel> getUserPoints(int userId);
  Future<List<PointTransactionModel>> getPointHistory(
    int userId, {
    int page = 0,
    int limit = 20,
  });
  Future<UserPointsModel> awardPoints({
    required int userId,
    required int points,
    required String action,
    required String description,
    int? referenceId,
  });
  Future<List<BadgeModel>> getAllBadges(int userId);
  Future<List<BadgeModel>> getEarnedBadges(int userId);
  Future<BadgeModel> getBadgeDetail(int badgeId, int userId);
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    required String period,
    int? courseId,
    int limit = 50,
  });
  Future<List<ChallengeModel>> getActiveChallenges(int userId);
  Future<List<ChallengeModel>> getCompletedChallenges(int userId);
  Future<ChallengeModel> claimChallengeReward(int challengeId, int userId);
  Future<UserPointsModel> recordDailyLogin(int userId);
}

class GamificationRemoteDataSourceImpl implements GamificationRemoteDataSource {
  final MoodleApiClient apiClient;

  GamificationRemoteDataSourceImpl({required this.apiClient});

  // ═══════════════════════════════════════════
  //  Points & XP
  // ═══════════════════════════════════════════

  @override
  Future<UserPointsModel> getUserPoints(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetUserPoints,
      params: {'userid': userId},
    );
    return UserPointsModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<List<PointTransactionModel>> getPointHistory(
    int userId, {
    int page = 0,
    int limit = 20,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetPointHistory,
      params: {'userid': userId, 'page': page, 'limit': limit},
    );

    if (response is List) {
      return response
          .map((j) =>
              PointTransactionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('transactions')) {
      return (response['transactions'] as List)
          .map((j) =>
              PointTransactionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<UserPointsModel> awardPoints({
    required int userId,
    required int points,
    required String action,
    required String description,
    int? referenceId,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfAwardPoints,
      params: {
        'userid': userId,
        'points': points,
        'action': action,
        'description': description,
        'referenceid': ?referenceId,
      },
    );
    return UserPointsModel.fromJson(response as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════
  //  Badges
  // ═══════════════════════════════════════════

  @override
  Future<List<BadgeModel>> getAllBadges(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetAllBadges,
      params: {'userid': userId},
    );

    if (response is List) {
      return response
          .map((j) => BadgeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('badges')) {
      return (response['badges'] as List)
          .map((j) => BadgeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<BadgeModel>> getEarnedBadges(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetEarnedBadges,
      params: {'userid': userId},
    );

    if (response is List) {
      return response
          .map((j) => BadgeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('badges')) {
      return (response['badges'] as List)
          .map((j) => BadgeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<BadgeModel> getBadgeDetail(int badgeId, int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetBadgeDetail,
      params: {'badgeid': badgeId, 'userid': userId},
    );
    return BadgeModel.fromJson(response as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════
  //  Leaderboard
  // ═══════════════════════════════════════════

  @override
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    required String period,
    int? courseId,
    int limit = 50,
  }) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetLeaderboard,
      params: {
        'period': period,
        'courseid': ?courseId,
        'limit': limit,
      },
    );

    if (response is List) {
      return response
          .map((j) =>
              LeaderboardEntryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('entries')) {
      return (response['entries'] as List)
          .map((j) =>
              LeaderboardEntryModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // ═══════════════════════════════════════════
  //  Challenges
  // ═══════════════════════════════════════════

  @override
  Future<List<ChallengeModel>> getActiveChallenges(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetActiveChallenges,
      params: {'userid': userId},
    );

    if (response is List) {
      return response
          .map((j) => ChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('challenges')) {
      return (response['challenges'] as List)
          .map((j) => ChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<ChallengeModel>> getCompletedChallenges(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetCompletedChallenges,
      params: {'userid': userId},
    );

    if (response is List) {
      return response
          .map((j) => ChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    if (response is Map && response.containsKey('challenges')) {
      return (response['challenges'] as List)
          .map((j) => ChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<ChallengeModel> claimChallengeReward(
    int challengeId,
    int userId,
  ) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfClaimChallengeReward,
      params: {'challengeid': challengeId, 'userid': userId},
    );
    return ChallengeModel.fromJson(response as Map<String, dynamic>);
  }

  // ═══════════════════════════════════════════
  //  Streaks
  // ═══════════════════════════════════════════

  @override
  Future<UserPointsModel> recordDailyLogin(int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfRecordDailyLogin,
      params: {'userid': userId},
    );
    return UserPointsModel.fromJson(response as Map<String, dynamic>);
  }
}
