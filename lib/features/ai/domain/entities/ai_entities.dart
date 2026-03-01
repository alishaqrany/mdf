import 'package:equatable/equatable.dart';

/// A course recommendation with a confidence score and reason.
class CourseRecommendation extends Equatable {
  final int courseId;
  final String courseName;
  final String? courseImage;
  final String? categoryName;
  final double confidenceScore; // 0.0 → 1.0
  final RecommendationReason reason;
  final String reasonText;

  const CourseRecommendation({
    required this.courseId,
    required this.courseName,
    this.courseImage,
    this.categoryName,
    required this.confidenceScore,
    required this.reason,
    required this.reasonText,
  });

  @override
  List<Object?> get props => [courseId, confidenceScore];
}

/// Why a course was recommended.
enum RecommendationReason {
  sameCategory, // Same category as completed courses
  popularAmongPeers, // Popular among users with similar profiles
  completionPath, // Logical next step after a completed course
  trendingNow, // Currently trending on the platform
  teacherMatch, // Same teacher as a highly-rated course
}

/// Performance prediction for a student in a course.
class PerformancePrediction extends Equatable {
  final int courseId;
  final String courseName;
  final double predictedGrade; // 0–100
  final RiskLevel riskLevel;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;
  final double completionLikelihood; // 0.0 → 1.0

  const PerformancePrediction({
    required this.courseId,
    required this.courseName,
    required this.predictedGrade,
    required this.riskLevel,
    this.strengths = const [],
    this.weaknesses = const [],
    this.suggestions = const [],
    required this.completionLikelihood,
  });

  @override
  List<Object?> get props => [courseId, predictedGrade];
}

enum RiskLevel { low, medium, high, critical }

/// A chat message in the AI assistant conversation.
class AiChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AiMessageType type;

  const AiChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = AiMessageType.text,
  });

  @override
  List<Object?> get props => [id];
}

enum AiMessageType { text, suggestion, courseCard, gradeChart, error }

/// A summarized piece of content.
class ContentSummary extends Equatable {
  final int moduleId;
  final String moduleTitle;
  final String originalType; // 'page', 'resource', 'forum', etc.
  final String summary;
  final List<String> keyPoints;
  final int estimatedReadTime; // minutes
  final DateTime generatedAt;

  const ContentSummary({
    required this.moduleId,
    required this.moduleTitle,
    required this.originalType,
    required this.summary,
    this.keyPoints = const [],
    required this.estimatedReadTime,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [moduleId];
}

/// Overall AI insights for a student.
class StudentInsights extends Equatable {
  final int userId;
  final double overallPerformance; // 0–100
  final String performanceTrend; // 'improving', 'stable', 'declining'
  final int studyStreak; // consecutive days
  final double weeklyActivityHours;
  final String strongestSubject;
  final String weakestSubject;
  final List<PerformancePrediction> predictions;
  final List<CourseRecommendation> recommendations;

  const StudentInsights({
    required this.userId,
    required this.overallPerformance,
    required this.performanceTrend,
    required this.studyStreak,
    required this.weeklyActivityHours,
    required this.strongestSubject,
    required this.weakestSubject,
    this.predictions = const [],
    this.recommendations = const [],
  });

  @override
  List<Object?> get props => [userId, overallPerformance];
}
