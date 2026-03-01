import '../../domain/entities/gamification_entities.dart';

// ─────────────────────────────────────────────
//  UserPoints Model
// ─────────────────────────────────────────────

class UserPointsModel extends UserPoints {
  const UserPointsModel({
    required super.userId,
    required super.fullName,
    super.profileImageUrl,
    super.totalPoints,
    super.level,
    super.currentLevelPoints,
    super.nextLevelPoints,
    super.currentStreak,
    super.longestStreak,
    super.lastActivityDate,
    super.rank,
    super.totalUsers,
  });

  factory UserPointsModel.fromJson(Map<String, dynamic> json) {
    return UserPointsModel(
      userId: json['userid'] as int? ?? 0,
      fullName: json['fullname'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      totalPoints: json['totalpoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentLevelPoints: json['currentlevelpoints'] as int? ?? 0,
      nextLevelPoints: json['nextlevelpoints'] as int? ?? 100,
      currentStreak: json['currentstreak'] as int? ?? 0,
      longestStreak: json['longeststreak'] as int? ?? 0,
      lastActivityDate: json['lastactivitydate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lastactivitydate'] as int) * 1000,
            )
          : null,
      rank: json['rank'] as int? ?? 0,
      totalUsers: json['totalusers'] as int? ?? 0,
    );
  }
}

// ─────────────────────────────────────────────
//  PointTransaction Model
// ─────────────────────────────────────────────

class PointTransactionModel extends PointTransaction {
  const PointTransactionModel({
    required super.id,
    required super.userId,
    required super.points,
    required super.action,
    required super.description,
    super.referenceId,
    required super.createdAt,
  });

  factory PointTransactionModel.fromJson(Map<String, dynamic> json) {
    return PointTransactionModel(
      id: json['id'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      action: _parseAction(json['action'] as String? ?? 'daily_login'),
      description: json['description'] as String? ?? '',
      referenceId: json['referenceid'] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['timecreated'] as int?) ?? 0) * 1000,
      ),
    );
  }

  static PointAction _parseAction(String action) {
    switch (action) {
      case 'course_enroll':
        return PointAction.courseEnroll;
      case 'module_complete':
        return PointAction.moduleComplete;
      case 'quiz_complete':
        return PointAction.quizComplete;
      case 'assignment_submit':
        return PointAction.assignmentSubmit;
      case 'forum_post':
        return PointAction.forumPost;
      case 'note_create':
        return PointAction.noteCreate;
      case 'review_complete':
        return PointAction.reviewComplete;
      case 'daily_login':
        return PointAction.dailyLogin;
      case 'streak_bonus':
        return PointAction.streakBonus;
      case 'challenge_complete':
        return PointAction.challengeComplete;
      case 'badge_earned':
        return PointAction.badgeEarned;
      default:
        return PointAction.dailyLogin;
    }
  }
}

// ─────────────────────────────────────────────
//  Badge Model
// ─────────────────────────────────────────────

class BadgeModel extends Badge {
  const BadgeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.iconName,
    super.category,
    super.rarity,
    super.requiredPoints,
    super.criteria,
    super.isEarned,
    super.earnedAt,
    super.earnedPercentage,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconName: json['iconname'] as String? ?? 'star',
      category: _parseCategory(json['category'] as String? ?? 'general'),
      rarity: _parseRarity(json['rarity'] as String? ?? 'common'),
      requiredPoints: json['requiredpoints'] as int? ?? 0,
      criteria: json['criteria'] as String?,
      isEarned: (json['isearned'] as int? ?? 0) == 1,
      earnedAt: json['earnedat'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['earnedat'] as int) * 1000,
            )
          : null,
      earnedPercentage: (json['earnedpercentage'] as num?)?.toDouble() ?? 0,
    );
  }

  static BadgeCategory _parseCategory(String cat) {
    switch (cat) {
      case 'courses':
        return BadgeCategory.courses;
      case 'quizzes':
        return BadgeCategory.quizzes;
      case 'assignments':
        return BadgeCategory.assignments;
      case 'social':
        return BadgeCategory.social;
      case 'streaks':
        return BadgeCategory.streaks;
      case 'special':
        return BadgeCategory.special;
      default:
        return BadgeCategory.general;
    }
  }

  static BadgeRarity _parseRarity(String rarity) {
    switch (rarity) {
      case 'uncommon':
        return BadgeRarity.uncommon;
      case 'rare':
        return BadgeRarity.rare;
      case 'epic':
        return BadgeRarity.epic;
      case 'legendary':
        return BadgeRarity.legendary;
      default:
        return BadgeRarity.common;
    }
  }
}

// ─────────────────────────────────────────────
//  LeaderboardEntry Model
// ─────────────────────────────────────────────

class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.rank,
    required super.userId,
    required super.fullName,
    super.profileImageUrl,
    required super.points,
    super.level,
    super.badgeCount,
    super.currentStreak,
    super.isCurrentUser,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      fullName: json['fullname'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      points: json['points'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      badgeCount: json['badgecount'] as int? ?? 0,
      currentStreak: json['currentstreak'] as int? ?? 0,
      isCurrentUser: (json['iscurrentuser'] as int? ?? 0) == 1,
    );
  }
}

// ─────────────────────────────────────────────
//  Challenge Model
// ─────────────────────────────────────────────

class ChallengeModel extends Challenge {
  const ChallengeModel({
    required super.id,
    required super.title,
    required super.description,
    super.type,
    super.period,
    required super.targetValue,
    super.currentValue,
    required super.rewardPoints,
    required super.startDate,
    required super.endDate,
    super.status,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: _parseType(json['type'] as String? ?? 'module_complete'),
      period: (json['period'] as String? ?? 'daily') == 'weekly'
          ? ChallengePeriod.weekly
          : ChallengePeriod.daily,
      targetValue: json['targetvalue'] as int? ?? 1,
      currentValue: json['currentvalue'] as int? ?? 0,
      rewardPoints: json['rewardpoints'] as int? ?? 0,
      startDate: DateTime.fromMillisecondsSinceEpoch(
        ((json['startdate'] as int?) ?? 0) * 1000,
      ),
      endDate: DateTime.fromMillisecondsSinceEpoch(
        ((json['enddate'] as int?) ?? 0) * 1000,
      ),
      status: _parseStatus(json['status'] as String? ?? 'active'),
    );
  }

  static ChallengeType _parseType(String type) {
    switch (type) {
      case 'quiz_score':
        return ChallengeType.quizScore;
      case 'forum_post':
        return ChallengeType.forumPost;
      case 'note_create':
        return ChallengeType.noteCreate;
      case 'course_enroll':
        return ChallengeType.courseEnroll;
      case 'login_streak':
        return ChallengeType.loginStreak;
      case 'study_time':
        return ChallengeType.studyTime;
      default:
        return ChallengeType.moduleComplete;
    }
  }

  static ChallengeStatus _parseStatus(String status) {
    switch (status) {
      case 'completed':
        return ChallengeStatus.completed;
      case 'expired':
        return ChallengeStatus.expired;
      case 'claimed':
        return ChallengeStatus.claimed;
      default:
        return ChallengeStatus.active;
    }
  }
}
