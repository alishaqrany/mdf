import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/ai_entities.dart';

/// Repository contract for all AI features.
abstract class AiRepository {
  /// Get smart course recommendations for a user.
  Future<Either<Failure, List<CourseRecommendation>>> getRecommendations(
    int userId,
  );

  /// Get performance predictions across enrolled courses.
  Future<Either<Failure, List<PerformancePrediction>>>
  getPerformancePredictions(int userId);

  /// Get full student insights (performance + recommendations).
  Future<Either<Failure, StudentInsights>> getStudentInsights(int userId);

  /// Send a message to the AI chatbot and receive a response.
  Future<Either<Failure, AiChatMessage>> chat(
    int userId,
    String message,
    List<AiChatMessage> history,
  );

  /// Summarize a course module's content.
  Future<Either<Failure, ContentSummary>> summarizeContent(
    int courseId,
    int moduleId,
  );

  /// Summarize an entire course.
  Future<Either<Failure, List<ContentSummary>>> summarizeCourse(int courseId);
}
