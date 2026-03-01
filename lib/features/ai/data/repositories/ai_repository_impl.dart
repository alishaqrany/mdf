import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../courses/domain/entities/course.dart';
import '../../../courses/domain/repositories/courses_repository.dart';
import '../../../course_content/domain/repositories/course_content_repository.dart';
import '../../../grades/domain/entities/grade.dart';
import '../../../grades/domain/repositories/grade_repository.dart';
import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_repository.dart';
import '../ai_engine.dart';

class AiRepositoryImpl implements AiRepository {
  final AiEngine aiEngine;
  final CoursesRepository coursesRepository;
  final CourseContentRepository courseContentRepository;
  final GradeRepository gradeRepository;
  final NetworkInfo networkInfo;

  AiRepositoryImpl({
    required this.aiEngine,
    required this.coursesRepository,
    required this.courseContentRepository,
    required this.gradeRepository,
    required this.networkInfo,
  });

  // Cache to avoid re-fetching within the same session
  List<Course>? _cachedCourses;
  List<CourseGrade>? _cachedGrades;
  Map<int, List<GradeItem>>? _cachedGradeItems;
  List<PerformancePrediction>? _cachedPredictions;
  int? _cachedUserId;

  Future<void> _ensureData(int userId) async {
    if (_cachedUserId == userId && _cachedCourses != null) return;
    _cachedUserId = userId;

    // Fetch enrolled courses
    final coursesResult = await coursesRepository.getEnrolledCourses(userId);
    _cachedCourses = coursesResult.fold((_) => <Course>[], (c) => c);

    // Fetch course grades
    final gradesResult = await gradeRepository.getCourseGrades(userId);
    _cachedGrades = gradesResult.fold((_) => <CourseGrade>[], (g) => g);

    // Fetch per-course grade items
    _cachedGradeItems = {};
    for (final course in _cachedCourses!.take(10)) {
      final itemsResult = await gradeRepository.getGradeItems(
        course.id,
        userId,
      );
      itemsResult.fold((_) {}, (items) {
        _cachedGradeItems![course.id] = items;
      });
    }

    // Build predictions
    _cachedPredictions = aiEngine.predictPerformance(
      enrolledCourses: _cachedCourses!,
      courseGrades: _cachedGrades!,
      gradeItems: _cachedGradeItems!,
    );
  }

  @override
  Future<Either<Failure, List<CourseRecommendation>>> getRecommendations(
    int userId,
  ) async {
    try {
      await _ensureData(userId);
      final recommendations = await aiEngine.generateRecommendations(
        userId: userId,
        enrolledCourses: _cachedCourses!,
        courseGrades: _cachedGrades!,
      );
      return Right(recommendations);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to generate recommendations: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<PerformancePrediction>>>
  getPerformancePredictions(int userId) async {
    try {
      await _ensureData(userId);
      return Right(_cachedPredictions!);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to generate predictions: $e'));
    }
  }

  @override
  Future<Either<Failure, StudentInsights>> getStudentInsights(
    int userId,
  ) async {
    try {
      await _ensureData(userId);

      final recommendations = await aiEngine.generateRecommendations(
        userId: userId,
        enrolledCourses: _cachedCourses!,
        courseGrades: _cachedGrades!,
      );

      final insights = aiEngine.buildInsights(
        userId: userId,
        enrolledCourses: _cachedCourses!,
        courseGrades: _cachedGrades!,
        predictions: _cachedPredictions!,
        recommendations: recommendations,
      );

      return Right(insights);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to build insights: $e'));
    }
  }

  @override
  Future<Either<Failure, AiChatMessage>> chat(
    int userId,
    String message,
    List<AiChatMessage> history,
  ) async {
    try {
      await _ensureData(userId);

      final response = aiEngine.generateResponse(
        userMessage: message,
        enrolledCourses: _cachedCourses!,
        courseGrades: _cachedGrades!,
        predictions: _cachedPredictions!,
      );

      return Right(response);
    } catch (e) {
      return Left(ServerFailure(message: 'Chat error: $e'));
    }
  }

  @override
  Future<Either<Failure, ContentSummary>> summarizeContent(
    int courseId,
    int moduleId,
  ) async {
    try {
      // Fetch course contents to find the module
      final contentsResult = await courseContentRepository.getCourseContents(
        courseId,
      );
      return contentsResult.fold((failure) => Left(failure), (sections) async {
        // Find the module in sections
        for (final section in sections) {
          for (final module in section.modules) {
            if (module.id == moduleId) {
              final summary = await aiEngine.summarizeModule(
                courseId: courseId,
                moduleId: moduleId,
                moduleTitle: module.name,
                moduleType: module.modName,
                htmlContent: module.description,
              );
              return Right(summary);
            }
          }
        }
        return const Left(ServerFailure(message: 'Module not found'));
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Summarization error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ContentSummary>>> summarizeCourse(
    int courseId,
  ) async {
    try {
      final contentsResult = await courseContentRepository.getCourseContents(
        courseId,
      );
      return contentsResult.fold((failure) => Left(failure), (sections) async {
        final summaries = <ContentSummary>[];
        for (final section in sections) {
          for (final module in section.modules) {
            if (module.description != null && module.description!.isNotEmpty) {
              final summary = await aiEngine.summarizeModule(
                courseId: courseId,
                moduleId: module.id,
                moduleTitle: module.name,
                moduleType: module.modName,
                htmlContent: module.description,
              );
              summaries.add(summary);
            }
          }
        }
        return Right(summaries);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Course summarization error: $e'));
    }
  }
}
