import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/quiz_model.dart';

abstract class QuizRemoteDataSource {
  Future<List<QuizModel>> getQuizzesByCourse(int courseId);
  Future<List<QuizAttemptModel>> getUserAttempts(int quizId, int userId);
  Future<QuizAttemptModel> startAttempt(int quizId);
  Future<List<QuizQuestionModel>> getAttemptData(int attemptId, int page);
  Future<void> saveAttempt(int attemptId, Map<String, String> data);
  Future<void> submitAttempt(int attemptId);
  Future<List<QuizQuestionModel>> getAttemptReview(int attemptId);
  Future<double?> getUserBestGrade(int quizId, int userId);
}

class QuizRemoteDataSourceImpl implements QuizRemoteDataSource {
  final MoodleApiClient apiClient;

  QuizRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<QuizModel>> getQuizzesByCourse(int courseId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getQuizzes,
      params: {'courseids[0]': courseId},
    );

    if (response is Map && response.containsKey('quizzes')) {
      return (response['quizzes'] as List)
          .map((j) => QuizModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<QuizAttemptModel>> getUserAttempts(int quizId, int userId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getUserAttempts,
      params: {'quizid': quizId, 'userid': userId, 'status': 'all'},
    );

    if (response is Map && response.containsKey('attempts')) {
      return (response['attempts'] as List)
          .map((j) => QuizAttemptModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<QuizAttemptModel> startAttempt(int quizId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.startAttempt,
      params: {'quizid': quizId},
    );

    final attemptJson = (response as Map<String, dynamic>)['attempt'];
    return QuizAttemptModel.fromJson(attemptJson as Map<String, dynamic>);
  }

  @override
  Future<List<QuizQuestionModel>> getAttemptData(
    int attemptId,
    int page,
  ) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getAttemptData,
      params: {'attemptid': attemptId, 'page': page},
    );

    if (response is Map && response.containsKey('questions')) {
      return (response['questions'] as List)
          .map((j) => QuizQuestionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveAttempt(int attemptId, Map<String, String> data) async {
    final params = <String, dynamic>{'attemptid': attemptId};
    int i = 0;
    for (final entry in data.entries) {
      params['data[$i][name]'] = entry.key;
      params['data[$i][value]'] = entry.value;
      i++;
    }
    await apiClient.call(MoodleApiEndpoints.saveAttempt, params: params);
  }

  @override
  Future<void> submitAttempt(int attemptId) async {
    await apiClient.call(
      MoodleApiEndpoints.processAttempt,
      params: {'attemptid': attemptId, 'finishattempt': 1},
    );
  }

  @override
  Future<List<QuizQuestionModel>> getAttemptReview(int attemptId) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.getAttemptReview,
      params: {'attemptid': attemptId},
    );

    if (response is Map && response.containsKey('questions')) {
      return (response['questions'] as List)
          .map((j) => QuizQuestionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<double?> getUserBestGrade(int quizId, int userId) async {
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getUserBestGrade,
        params: {'quizid': quizId, 'userid': userId},
      );
      if (response is Map && response.containsKey('grade')) {
        return (response['grade'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }
}
