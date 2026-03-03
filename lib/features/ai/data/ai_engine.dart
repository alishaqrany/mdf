import 'dart:math';

import '../../../core/api/moodle_api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../courses/domain/entities/course.dart';
import '../../grades/domain/entities/grade.dart';
import '../domain/entities/ai_entities.dart';

/// Local AI engine that generates recommendations, predictions, and summaries
/// based on the student's Moodle data (courses, grades, activity).
///
/// This is a client-side heuristic engine. For production, it can be backed
/// by a server-side ML model.
class AiEngine {
  final MoodleApiClient _apiClient;

  AiEngine({required MoodleApiClient apiClient}) : _apiClient = apiClient;

  // ─────────────────────────────────────────────────────
  //  RECOMMENDATIONS
  // ─────────────────────────────────────────────────────

  /// Generate course recommendations for the given user.
  Future<List<CourseRecommendation>> generateRecommendations({
    required int userId,
    required List<Course> enrolledCourses,
    required List<CourseGrade> courseGrades,
  }) async {
    final recommendations = <CourseRecommendation>[];

    // 1. Fetch all available courses
    List<Course> allCourses;
    try {
      final response = await _apiClient.call(
        MoodleApiEndpoints.searchCourses,
        params: {'criterianame': 'search', 'criteriavalue': ''},
      );
      final coursesData = response['courses'] as List? ?? [];
      allCourses = coursesData
          .map((c) => Course(
                id: c['id'] ?? 0,
                shortName: c['shortname'] ?? '',
                fullName: c['fullname'] ?? '',
                categoryId: c['categoryid'],
                categoryName: c['categoryname'],
                imageUrl: c['overviewfiles'] != null &&
                        (c['overviewfiles'] as List).isNotEmpty
                    ? c['overviewfiles'][0]['fileurl']
                    : null,
                summary: c['summary'],
              ))
          .toList();
    } catch (_) {
      allCourses = [];
    }

    final enrolledIds = enrolledCourses.map((c) => c.id).toSet();

    // Filter not-enrolled courses
    final candidates =
        allCourses.where((c) => !enrolledIds.contains(c.id)).toList();

    // 2. Same-category recommendations
    final enrolledCategories =
        enrolledCourses.map((c) => c.categoryId).whereType<int>().toSet();
    for (final course in candidates) {
      if (course.categoryId != null &&
          enrolledCategories.contains(course.categoryId)) {
        recommendations.add(CourseRecommendation(
          courseId: course.id,
          courseName: course.fullName,
          courseImage: course.imageUrl,
          categoryName: course.categoryName,
          confidenceScore: 0.85,
          reason: RecommendationReason.sameCategory,
          reasonText:
              'Based on your interest in ${course.categoryName ?? "this subject"}',
        ));
      }
    }

    // 3. Popular courses (by enrollment count)
    final popular = List.of(candidates)
      ..sort((a, b) =>
          (b.enrolledUserCount ?? 0).compareTo(a.enrolledUserCount ?? 0));
    for (final course in popular.take(3)) {
      if (!recommendations.any((r) => r.courseId == course.id)) {
        recommendations.add(CourseRecommendation(
          courseId: course.id,
          courseName: course.fullName,
          courseImage: course.imageUrl,
          categoryName: course.categoryName,
          confidenceScore: 0.70,
          reason: RecommendationReason.popularAmongPeers,
          reasonText:
              '${course.enrolledUserCount ?? 0} students enrolled',
        ));
      }
    }

    // 4. Completion-path: if user completed courses, suggest next-level ones
    final completedCategories = enrolledCourses
        .where((c) =>
            c.completed == true ||
            (c.progress != null && c.progress! >= 100))
        .map((c) => c.categoryId)
        .whereType<int>()
        .toSet();

    for (final course in candidates) {
      if (course.categoryId != null &&
          completedCategories.contains(course.categoryId) &&
          !recommendations.any((r) => r.courseId == course.id)) {
        recommendations.add(CourseRecommendation(
          courseId: course.id,
          courseName: course.fullName,
          courseImage: course.imageUrl,
          categoryName: course.categoryName,
          confidenceScore: 0.90,
          reason: RecommendationReason.completionPath,
          reasonText: 'Next step after completing courses in this subject',
        ));
      }
    }

    // Sort by confidence descending
    recommendations.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    return recommendations.take(10).toList();
  }

  // ─────────────────────────────────────────────────────
  //  PERFORMANCE PREDICTIONS
  // ─────────────────────────────────────────────────────

  /// Analyze grades and activity to predict performance per course.
  List<PerformancePrediction> predictPerformance({
    required List<Course> enrolledCourses,
    required List<CourseGrade> courseGrades,
    required Map<int, List<GradeItem>> gradeItems,
  }) {
    final predictions = <PerformancePrediction>[];

    for (final course in enrolledCourses) {
      final courseGrade = courseGrades.firstWhere(
        (g) => g.courseId == course.id,
        orElse: () => CourseGrade(courseId: course.id, courseName: course.fullName),
      );

      final items = gradeItems[course.id] ?? [];
      final gradedItems =
          items.where((i) => i.gradeRaw != null && i.gradeMax != null);

      double avgPercent = 0;
      if (gradedItems.isNotEmpty) {
        avgPercent = gradedItems
                .map((i) {
                  final raw = i.gradeRaw ?? 0;
                  final maxVal = (i.gradeMax ?? 0) == 0 ? 1.0 : i.gradeMax!;
                  return (raw / maxVal) * 100;
                })
                .reduce((a, b) => a + b) /
            gradedItems.length;
      } else if (courseGrade.grade != null) {
        avgPercent = courseGrade.grade!;
      }

      final progress = course.progress ?? 0;

      // Predict final grade using weighted average + progress factor
      final predicted = _predictGrade(avgPercent, progress);
      final risk = _assessRisk(predicted, progress);
      final strengths = <String>[];
      final weaknesses = <String>[];
      final suggestions = <String>[];

      // Analyze individual items
      for (final item in gradedItems) {
        final raw = item.gradeRaw ?? 0;
        final maxVal = (item.gradeMax ?? 0) == 0 ? 1.0 : item.gradeMax!;
        final pct = (raw / maxVal) * 100;
        if (pct >= 80) {
          strengths.add(item.itemName);
        } else if (pct < 50) {
          weaknesses.add(item.itemName);
        }
      }

      // Generate suggestions
      if (risk == RiskLevel.high || risk == RiskLevel.critical) {
        suggestions.add('Focus on improving weak activities');
        suggestions.add('Consider reaching out to the instructor');
      }
      if (progress < 50) {
        suggestions.add('Catch up on incomplete course content');
      }
      if (weaknesses.isNotEmpty) {
        suggestions.add(
            'Review material for: ${weaknesses.take(3).join(", ")}');
      }

      predictions.add(PerformancePrediction(
        courseId: course.id,
        courseName: course.fullName,
        predictedGrade: predicted.clamp(0, 100),
        riskLevel: risk,
        strengths: strengths.take(5).toList(),
        weaknesses: weaknesses.take(5).toList(),
        suggestions: suggestions.take(5).toList(),
        completionLikelihood: _completionLikelihood(progress, predicted),
      ));
    }

    return predictions;
  }

  double _predictGrade(double currentAvg, double progress) {
    if (currentAvg == 0 && progress == 0) return 0;
    // Weight: 70% current performance, 30% engagement (progress)
    return (currentAvg * 0.7) + (progress * 0.3);
  }

  RiskLevel _assessRisk(double predicted, double progress) {
    if (predicted <= 30 || (progress < 20 && predicted < 60)) {
      return RiskLevel.critical;
    }
    if (predicted <= 50) return RiskLevel.high;
    if (predicted <= 70) return RiskLevel.medium;
    return RiskLevel.low;
  }

  double _completionLikelihood(double progress, double predicted) {
    final score = (progress / 100 * 0.6) + (predicted / 100 * 0.4);
    return score.clamp(0.0, 1.0);
  }

  // ─────────────────────────────────────────────────────
  //  STUDENT INSIGHTS
  // ─────────────────────────────────────────────────────

  StudentInsights buildInsights({
    required int userId,
    required List<Course> enrolledCourses,
    required List<CourseGrade> courseGrades,
    required List<PerformancePrediction> predictions,
    required List<CourseRecommendation> recommendations,
  }) {
    // Average performance
    final gradedCourses = courseGrades.where((g) => g.grade != null);
    final avgPerformance = gradedCourses.isNotEmpty
        ? gradedCourses.map((g) => g.grade!).reduce((a, b) => a + b) /
            gradedCourses.length
        : 0.0;

    // Determine trend from predictions
    final atRisk = predictions.where(
        (p) => p.riskLevel == RiskLevel.high || p.riskLevel == RiskLevel.critical);
    final strong = predictions.where((p) => p.riskLevel == RiskLevel.low);
    String trend = 'stable';
    if (strong.length > atRisk.length) trend = 'improving';
    if (atRisk.length > strong.length) trend = 'declining';

    // Strongest/weakest
    String strongest = '-';
    String weakest = '-';
    if (predictions.isNotEmpty) {
      final sorted = List.of(predictions)
        ..sort((a, b) => b.predictedGrade.compareTo(a.predictedGrade));
      strongest = sorted.first.courseName;
      weakest = sorted.last.courseName;
    }

    // Study streak (estimate from recent courses' lastAccess)
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 1000;
      final dayEnd = dayStart + 86400;
      final hasActivity = enrolledCourses.any(
        (c) => c.lastAccess != null && c.lastAccess! >= dayStart && c.lastAccess! < dayEnd,
      );
      if (hasActivity) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return StudentInsights(
      userId: userId,
      overallPerformance: avgPerformance,
      performanceTrend: trend,
      studyStreak: streak,
      weeklyActivityHours: _estimateWeeklyHours(enrolledCourses),
      strongestSubject: strongest,
      weakestSubject: weakest,
      predictions: predictions,
      recommendations: recommendations,
    );
  }

  double _estimateWeeklyHours(List<Course> courses) {
    // Rough estimate: 2h per active course per week
    final activeCourses = courses.where(
      (c) => c.progress != null && c.progress! > 0 && c.progress! < 100,
    );
    return (activeCourses.length * 2.0).clamp(0, 40);
  }

  // ─────────────────────────────────────────────────────
  //  CHATBOT
  // ─────────────────────────────────────────────────────

  /// Simple rule-based chatbot that answers questions about courses,
  /// grades, deadlines, and provides study suggestions.
  AiChatMessage generateResponse({
    required String userMessage,
    required List<Course> enrolledCourses,
    required List<CourseGrade> courseGrades,
    required List<PerformancePrediction> predictions,
  }) {
    final msg = userMessage.toLowerCase().trim();
    String reply;
    AiMessageType type = AiMessageType.text;

    if (_matchesAny(msg, ['courses', 'مقررات', 'كورسات', 'enrolled', 'مسجل'])) {
      reply = _coursesResponse(enrolledCourses);
      type = AiMessageType.courseCard;
    } else if (_matchesAny(msg, ['grade', 'درجات', 'درجة', 'marks', 'score', 'نتائج'])) {
      reply = _gradesResponse(courseGrades);
      type = AiMessageType.gradeChart;
    } else if (_matchesAny(msg, ['help', 'مساعدة', 'suggest', 'اقتراح', 'advice', 'نصيحة', 'improve', 'تحسين'])) {
      reply = _suggestionsResponse(predictions);
      type = AiMessageType.suggestion;
    } else if (_matchesAny(msg, ['progress', 'تقدم', 'performance', 'أداء'])) {
      reply = _performanceResponse(predictions);
    } else if (_matchesAny(msg, ['deadline', 'موعد', 'due', 'تسليم', 'calendar'])) {
      reply = 'Check the Calendar tab for upcoming deadlines and events. '
          'You can also enable notifications to stay updated.';
    } else if (_matchesAny(msg, ['hi', 'hello', 'مرحبا', 'اهلا', 'السلام'])) {
      reply = 'Hello! 👋 I\'m your AI study assistant. Ask me about your '
          'courses, grades, performance, or study suggestions!';
    } else {
      reply = 'I can help you with:\n'
          '• **My courses** — View enrolled courses\n'
          '• **My grades** — Check your grades\n'
          '• **How can I improve?** — Get study suggestions\n'
          '• **My progress** — See performance predictions\n'
          '• **Deadlines** — Upcoming due dates\n\n'
          'Try asking one of these!';
    }

    return AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: reply,
      isUser: false,
      timestamp: DateTime.now(),
      type: type,
    );
  }

  bool _matchesAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));

  String _coursesResponse(List<Course> courses) {
    if (courses.isEmpty) return 'You have no enrolled courses yet.';
    final buffer = StringBuffer('You are enrolled in ${courses.length} courses:\n\n');
    for (final c in courses.take(8)) {
      final pct = c.progress?.toInt() ?? 0;
      buffer.writeln('• **${c.fullName}** — $pct% complete');
    }
    if (courses.length > 8) buffer.writeln('...and ${courses.length - 8} more');
    return buffer.toString();
  }

  String _gradesResponse(List<CourseGrade> grades) {
    if (grades.isEmpty) return 'No grades available yet.';
    final buffer = StringBuffer('Your grades overview:\n\n');
    for (final g in grades.take(8)) {
      final grade = g.grade != null ? '${g.grade!.toStringAsFixed(1)}%' : 'N/A';
      buffer.writeln('• **${g.courseName}** — $grade');
    }
    return buffer.toString();
  }

  String _suggestionsResponse(List<PerformancePrediction> predictions) {
    final atRisk = predictions
        .where((p) =>
            p.riskLevel == RiskLevel.high ||
            p.riskLevel == RiskLevel.critical)
        .toList();

    if (atRisk.isEmpty) {
      return '🎉 Great job! You\'re performing well in all your courses. '
          'Keep up the consistency!';
    }

    final buffer = StringBuffer('Here are my study suggestions:\n\n');
    for (final p in atRisk) {
      buffer.writeln('📚 **${p.courseName}** (Predicted: ${p.predictedGrade.toStringAsFixed(0)}%)');
      for (final s in p.suggestions.take(2)) {
        buffer.writeln('   → $s');
      }
      buffer.writeln('');
    }
    return buffer.toString();
  }

  String _performanceResponse(List<PerformancePrediction> predictions) {
    if (predictions.isEmpty) return 'No performance data available yet.';
    final buffer = StringBuffer('Performance predictions:\n\n');
    for (final p in predictions.take(8)) {
      final icon = p.riskLevel == RiskLevel.low
          ? '🟢'
          : p.riskLevel == RiskLevel.medium
              ? '🟡'
              : '🔴';
      buffer.writeln(
          '$icon **${p.courseName}** — Predicted: ${p.predictedGrade.toStringAsFixed(0)}%');
    }
    return buffer.toString();
  }

  // ─────────────────────────────────────────────────────
  //  CONTENT SUMMARIZATION
  // ─────────────────────────────────────────────────────

  /// Summarize course content by extracting key text from modules.
  Future<ContentSummary> summarizeModule({
    required int courseId,
    required int moduleId,
    required String moduleTitle,
    required String moduleType,
    required String? htmlContent,
  }) async {
    // Extract text from HTML
    final plainText = _stripHtml(htmlContent ?? '');

    // Generate summary using extractive summarization
    final sentences = _splitSentences(plainText);
    final summary = _extractiveSummary(sentences, maxSentences: 3);
    final keyPoints = _extractKeyPoints(sentences, maxPoints: 5);

    // Estimate read time (~200 words/min)
    final wordCount = plainText.split(RegExp(r'\s+')).length;
    final readTime = max(1, (wordCount / 200).ceil());

    return ContentSummary(
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      originalType: moduleType,
      summary: summary.isNotEmpty ? summary : 'No summary available for this content.',
      keyPoints: keyPoints,
      estimatedReadTime: readTime,
      generatedAt: DateTime.now(),
    );
  }

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '')
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'&[a-zA-Z]+;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?。؟]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 20)
        .toList();
  }

  /// Simple extractive summarization: pick most informative sentences.
  String _extractiveSummary(List<String> sentences, {int maxSentences = 3}) {
    if (sentences.isEmpty) return '';
    if (sentences.length <= maxSentences) return '${sentences.join('. ')}.';

    // Score sentences by word count and position
    final scored = <int, double>{};
    for (int i = 0; i < sentences.length; i++) {
      final words = sentences[i].split(RegExp(r'\s+')).length;
      final positionScore = 1.0 - (i / sentences.length * 0.5);
      final lengthScore = words > 5 ? (words / 30.0).clamp(0.0, 1.0) : 0.0;
      scored[i] = positionScore * 0.4 + lengthScore * 0.6;
    }

    final topIndices = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final selected = topIndices
        .take(maxSentences)
        .map((e) => e.key)
        .toList()
      ..sort();

    return '${selected.map((i) => sentences[i]).join('. ')}.';
  }

  List<String> _extractKeyPoints(List<String> sentences, {int maxPoints = 5}) {
    if (sentences.isEmpty) return [];
    // Pick diverse sentences
    final step = max(1, sentences.length ~/ maxPoints);
    return List.generate(
      min(maxPoints, sentences.length),
      (i) => sentences[min(i * step, sentences.length - 1)],
    );
  }
}
