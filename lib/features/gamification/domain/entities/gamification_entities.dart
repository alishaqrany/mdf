import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────
//  User Points / XP
// ─────────────────────────────────────────────

/// Represents a user's gamification profile with points, level and streak.
class UserPoints extends Equatable {
  final int userId;
  final String fullName;
  final String? profileImageUrl;
  final int totalPoints;
  final int level;
  final int currentLevelPoints;
  final int nextLevelPoints;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;
  final int rank;
  final int totalUsers;

  const UserPoints({
    required this.userId,
    required this.fullName,
    this.profileImageUrl,
    this.totalPoints = 0,
    this.level = 1,
    this.currentLevelPoints = 0,
    this.nextLevelPoints = 100,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.rank = 0,
    this.totalUsers = 0,
  });

  double get levelProgress =>
      nextLevelPoints > 0 ? currentLevelPoints / nextLevelPoints : 0;

  String get levelTitle => _levelTitle(level);

  static String _levelTitle(int level) {
    if (level <= 5) return 'مبتدئ'; // Beginner
    if (level <= 10) return 'متعلم'; // Learner
    if (level <= 20) return 'متقدم'; // Advanced
    if (level <= 35) return 'خبير'; // Expert
    return 'أسطورة'; // Legend
  }

  @override
  List<Object?> get props => [userId, totalPoints, level, currentStreak];
}

/// A single point-earning event (transaction).
class PointTransaction extends Equatable {
  final int id;
  final int userId;
  final int points;
  final PointAction action;
  final String description;
  final int? referenceId;
  final DateTime createdAt;

  const PointTransaction({
    required this.id,
    required this.userId,
    required this.points,
    required this.action,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, points, action];
}

enum PointAction {
  courseEnroll,
  moduleComplete,
  quizComplete,
  assignmentSubmit,
  forumPost,
  noteCreate,
  reviewComplete,
  dailyLogin,
  streakBonus,
  challengeComplete,
  badgeEarned,
}

// ─────────────────────────────────────────────
//  Badges / Achievements
// ─────────────────────────────────────────────

/// An achievement badge that users can earn.
class Badge extends Equatable {
  final int id;
  final String name;
  final String description;
  final String iconName;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final int requiredPoints;
  final String? criteria;
  final bool isEarned;
  final DateTime? earnedAt;
  final double earnedPercentage; // how many users earned it

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    this.category = BadgeCategory.general,
    this.rarity = BadgeRarity.common,
    this.requiredPoints = 0,
    this.criteria,
    this.isEarned = false,
    this.earnedAt,
    this.earnedPercentage = 0,
  });

  @override
  List<Object?> get props => [id, name, isEarned];
}

enum BadgeCategory {
  general,
  courses,
  quizzes,
  assignments,
  social,
  streaks,
  special,
}

enum BadgeRarity { common, uncommon, rare, epic, legendary }

// ─────────────────────────────────────────────
//  Leaderboard
// ─────────────────────────────────────────────

/// A leaderboard entry for ranking users.
class LeaderboardEntry extends Equatable {
  final int rank;
  final int userId;
  final String fullName;
  final String? profileImageUrl;
  final int points;
  final int level;
  final int badgeCount;
  final int currentStreak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.fullName,
    this.profileImageUrl,
    required this.points,
    this.level = 1,
    this.badgeCount = 0,
    this.currentStreak = 0,
    this.isCurrentUser = false,
  });

  @override
  List<Object?> get props => [rank, userId, points];
}

enum LeaderboardPeriod { daily, weekly, monthly, allTime }

// ─────────────────────────────────────────────
//  Challenges
// ─────────────────────────────────────────────

/// A daily or weekly challenge for the user.
class Challenge extends Equatable {
  final int id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengePeriod period;
  final int targetValue;
  final int currentValue;
  final int rewardPoints;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    this.type = ChallengeType.moduleComplete,
    this.period = ChallengePeriod.daily,
    required this.targetValue,
    this.currentValue = 0,
    required this.rewardPoints,
    required this.startDate,
    required this.endDate,
    this.status = ChallengeStatus.active,
  });

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;

  bool get isCompleted => currentValue >= targetValue;

  bool get isExpired => DateTime.now().isAfter(endDate);

  Duration get remainingTime => endDate.difference(DateTime.now());

  @override
  List<Object?> get props => [id, title, status];
}

enum ChallengeType {
  moduleComplete,
  quizScore,
  forumPost,
  noteCreate,
  courseEnroll,
  loginStreak,
  studyTime,
}

enum ChallengePeriod { daily, weekly }

enum ChallengeStatus { active, completed, expired, claimed }
