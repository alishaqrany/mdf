import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/features/gamification/data/models/gamification_models.dart';
import 'package:mdf_app/features/gamification/domain/entities/gamification_entities.dart';

void main() {
  // ───────────────────── UserPointsModel ─────────────────────
  group('UserPointsModel.fromJson', () {
    test('should parse all fields', () {
      final model = UserPointsModel.fromJson(const {
        'userid': 1,
        'fullname': 'Alice',
        'profileimageurl': 'https://img.com/a.png',
        'totalpoints': 500,
        'level': 3,
        'currentlevelpoints': 200,
        'nextlevelpoints': 300,
        'currentstreak': 7,
        'longeststreak': 14,
        'lastactivitydate': 1700000000,
        'rank': 5,
        'totalusers': 100,
      });
      expect(model.userId, 1);
      expect(model.fullName, 'Alice');
      expect(model.profileImageUrl, 'https://img.com/a.png');
      expect(model.totalPoints, 500);
      expect(model.level, 3);
      expect(model.currentLevelPoints, 200);
      expect(model.nextLevelPoints, 300);
      expect(model.currentStreak, 7);
      expect(model.longestStreak, 14);
      expect(
        model.lastActivityDate,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      expect(model.rank, 5);
      expect(model.totalUsers, 100);
    });

    test('should use defaults for missing fields', () {
      final model = UserPointsModel.fromJson(const {});
      expect(model.userId, 0);
      expect(model.fullName, '');
      expect(model.totalPoints, 0);
      expect(model.level, 1);
      expect(model.nextLevelPoints, 100);
      expect(model.lastActivityDate, isNull);
    });
  });

  // ───────────────────── PointTransactionModel ─────────────────────
  group('PointTransactionModel.fromJson', () {
    test('should parse with known action', () {
      final model = PointTransactionModel.fromJson(const {
        'id': 10,
        'userid': 1,
        'points': 50,
        'action': 'quiz_complete',
        'description': 'Completed Quiz 1',
        'referenceid': 42,
        'timecreated': 1700000000,
      });
      expect(model.id, 10);
      expect(model.userId, 1);
      expect(model.points, 50);
      expect(model.action, PointAction.quizComplete);
      expect(model.description, 'Completed Quiz 1');
      expect(model.referenceId, 42);
      expect(
        model.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
    });

    test('should parse all PointAction values', () {
      final actions = {
        'course_enroll': PointAction.courseEnroll,
        'module_complete': PointAction.moduleComplete,
        'quiz_complete': PointAction.quizComplete,
        'assignment_submit': PointAction.assignmentSubmit,
        'forum_post': PointAction.forumPost,
        'note_create': PointAction.noteCreate,
        'review_complete': PointAction.reviewComplete,
        'daily_login': PointAction.dailyLogin,
        'streak_bonus': PointAction.streakBonus,
        'challenge_complete': PointAction.challengeComplete,
        'badge_earned': PointAction.badgeEarned,
      };
      for (final entry in actions.entries) {
        final model = PointTransactionModel.fromJson({
          'id': 1,
          'userid': 1,
          'points': 10,
          'action': entry.key,
          'description': 'test',
          'timecreated': 0,
        });
        expect(model.action, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('should default unknown action to dailyLogin', () {
      final model = PointTransactionModel.fromJson(const {
        'id': 1,
        'userid': 1,
        'points': 10,
        'action': 'unknown_action',
        'description': 'test',
        'timecreated': 0,
      });
      expect(model.action, PointAction.dailyLogin);
    });
  });

  // ───────────────────── BadgeModel ─────────────────────
  group('BadgeModel.fromJson', () {
    test('should parse all fields', () {
      final model = BadgeModel.fromJson(const {
        'id': 1,
        'name': 'Quiz Master',
        'description': 'Complete 10 quizzes',
        'iconname': 'quiz_badge',
        'category': 'quizzes',
        'rarity': 'rare',
        'requiredpoints': 200,
        'criteria': 'Complete 10 quizzes',
        'isearned': 1,
        'earnedat': 1700000000,
        'earnedpercentage': 75.5,
      });
      expect(model.id, 1);
      expect(model.name, 'Quiz Master');
      expect(model.description, 'Complete 10 quizzes');
      expect(model.iconName, 'quiz_badge');
      expect(model.category, BadgeCategory.quizzes);
      expect(model.rarity, BadgeRarity.rare);
      expect(model.requiredPoints, 200);
      expect(model.criteria, 'Complete 10 quizzes');
      expect(model.isEarned, true);
      expect(
        model.earnedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      expect(model.earnedPercentage, 75.5);
    });

    test('should parse all categories', () {
      final cats = {
        'general': BadgeCategory.general,
        'courses': BadgeCategory.courses,
        'quizzes': BadgeCategory.quizzes,
        'assignments': BadgeCategory.assignments,
        'social': BadgeCategory.social,
        'streaks': BadgeCategory.streaks,
        'special': BadgeCategory.special,
      };
      for (final entry in cats.entries) {
        final model = BadgeModel.fromJson({
          'id': 1,
          'name': 'x',
          'description': 'x',
          'iconname': 'x',
          'category': entry.key,
        });
        expect(model.category, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('should parse all rarities', () {
      final rarities = {
        'common': BadgeRarity.common,
        'uncommon': BadgeRarity.uncommon,
        'rare': BadgeRarity.rare,
        'epic': BadgeRarity.epic,
        'legendary': BadgeRarity.legendary,
      };
      for (final entry in rarities.entries) {
        final model = BadgeModel.fromJson({
          'id': 1,
          'name': 'x',
          'description': 'x',
          'iconname': 'x',
          'rarity': entry.key,
        });
        expect(model.rarity, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('should handle isearned=0 as false', () {
      final model = BadgeModel.fromJson(const {
        'id': 1,
        'name': 'x',
        'description': 'x',
        'iconname': 'x',
        'isearned': 0,
      });
      expect(model.isEarned, false);
    });

    test('should default missing fields', () {
      final model = BadgeModel.fromJson(const {});
      expect(model.id, 0);
      expect(model.name, '');
      expect(model.iconName, 'star');
      expect(model.category, BadgeCategory.general);
      expect(model.rarity, BadgeRarity.common);
      expect(model.isEarned, false);
      expect(model.earnedAt, isNull);
      expect(model.earnedPercentage, 0);
    });
  });

  // ───────────────────── LeaderboardEntryModel ─────────────────────
  group('LeaderboardEntryModel.fromJson', () {
    test('should parse all fields', () {
      final model = LeaderboardEntryModel.fromJson(const {
        'rank': 1,
        'userid': 42,
        'fullname': 'Top Student',
        'profileimageurl': 'https://img.com/top.png',
        'points': 1000,
        'level': 5,
        'badgecount': 12,
        'currentstreak': 30,
        'iscurrentuser': 1,
      });
      expect(model.rank, 1);
      expect(model.userId, 42);
      expect(model.fullName, 'Top Student');
      expect(model.points, 1000);
      expect(model.level, 5);
      expect(model.badgeCount, 12);
      expect(model.currentStreak, 30);
      expect(model.isCurrentUser, true);
    });

    test('should handle iscurrentuser=0 as false', () {
      final model = LeaderboardEntryModel.fromJson(const {
        'rank': 2,
        'userid': 1,
        'fullname': 'x',
        'points': 0,
        'iscurrentuser': 0,
      });
      expect(model.isCurrentUser, false);
    });

    test('should use defaults for missing fields', () {
      final model = LeaderboardEntryModel.fromJson(const {});
      expect(model.rank, 0);
      expect(model.level, 1);
      expect(model.badgeCount, 0);
      expect(model.isCurrentUser, false);
    });
  });

  // ───────────────────── ChallengeModel ─────────────────────
  group('ChallengeModel.fromJson', () {
    test('should parse all fields', () {
      final model = ChallengeModel.fromJson(const {
        'id': 1,
        'title': 'Weekly Quiz Challenge',
        'description': 'Complete 5 quizzes this week',
        'type': 'quiz_score',
        'period': 'weekly',
        'targetvalue': 5,
        'currentvalue': 3,
        'rewardpoints': 100,
        'startdate': 1700000000,
        'enddate': 1700604800,
        'status': 'active',
      });
      expect(model.id, 1);
      expect(model.title, 'Weekly Quiz Challenge');
      expect(model.type, ChallengeType.quizScore);
      expect(model.period, ChallengePeriod.weekly);
      expect(model.targetValue, 5);
      expect(model.currentValue, 3);
      expect(model.rewardPoints, 100);
      expect(
        model.startDate,
        DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000),
      );
      expect(
        model.endDate,
        DateTime.fromMillisecondsSinceEpoch(1700604800 * 1000),
      );
      expect(model.status, ChallengeStatus.active);
    });

    test('should parse all challenge types', () {
      final types = {
        'module_complete': ChallengeType.moduleComplete,
        'quiz_score': ChallengeType.quizScore,
        'forum_post': ChallengeType.forumPost,
        'note_create': ChallengeType.noteCreate,
        'course_enroll': ChallengeType.courseEnroll,
        'login_streak': ChallengeType.loginStreak,
        'study_time': ChallengeType.studyTime,
      };
      for (final entry in types.entries) {
        final model = ChallengeModel.fromJson({
          'id': 1,
          'title': 'x',
          'description': 'x',
          'type': entry.key,
          'targetvalue': 1,
          'rewardpoints': 10,
          'startdate': 0,
          'enddate': 0,
        });
        expect(model.type, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('should parse all challenge statuses', () {
      final statuses = {
        'active': ChallengeStatus.active,
        'completed': ChallengeStatus.completed,
        'expired': ChallengeStatus.expired,
        'claimed': ChallengeStatus.claimed,
      };
      for (final entry in statuses.entries) {
        final model = ChallengeModel.fromJson({
          'id': 1,
          'title': 'x',
          'description': 'x',
          'targetvalue': 1,
          'rewardpoints': 10,
          'startdate': 0,
          'enddate': 0,
          'status': entry.key,
        });
        expect(model.status, entry.value, reason: 'Failed for ${entry.key}');
      }
    });

    test('should default period to daily', () {
      final model = ChallengeModel.fromJson(const {
        'id': 1,
        'title': 'x',
        'description': 'x',
        'targetvalue': 1,
        'rewardpoints': 10,
        'startdate': 0,
        'enddate': 0,
      });
      expect(model.period, ChallengePeriod.daily);
    });
  });
}
