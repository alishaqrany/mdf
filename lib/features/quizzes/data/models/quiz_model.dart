import '../../domain/entities/quiz.dart';

class QuizModel extends Quiz {
  const QuizModel({
    required super.id,
    required super.courseId,
    required super.name,
    super.intro,
    super.timeOpen,
    super.timeClose,
    super.timeLimit,
    super.attempts,
    super.gradeMethod,
    super.grade,
    super.hasQuestions,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      id: json['id'] as int,
      courseId: json['course'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      intro: json['intro'] as String?,
      timeOpen: json['timeopen'] as int?,
      timeClose: json['timeclose'] as int?,
      timeLimit: json['timelimit'] as int?,
      attempts: json['attempts'] as int?,
      gradeMethod: json['grademethod']?.toString(),
      grade: (json['grade'] as num?)?.toDouble(),
      hasQuestions: json['hasquestions'] == 1,
    );
  }
}

class QuizAttemptModel extends QuizAttempt {
  const QuizAttemptModel({
    required super.id,
    required super.quizId,
    required super.userId,
    required super.attempt,
    required super.state,
    super.timeStart,
    super.timeFinish,
    super.timeModified,
    super.sumGrades,
  });

  factory QuizAttemptModel.fromJson(Map<String, dynamic> json) {
    return QuizAttemptModel(
      id: json['id'] as int,
      quizId: json['quiz'] as int? ?? 0,
      userId: json['userid'] as int? ?? 0,
      attempt: json['attempt'] as int? ?? 0,
      state: json['state'] as String? ?? '',
      timeStart: json['timestart'] as int?,
      timeFinish: json['timefinish'] as int?,
      timeModified: json['timemodified'] as int?,
      sumGrades: (json['sumgrades'] as num?)?.toDouble(),
    );
  }
}

class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.slot,
    required super.type,
    required super.html,
    super.sequenceCheck,
    super.flagged,
    super.state,
    super.mark,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      slot: json['slot'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      html: json['html'] as String? ?? '',
      sequenceCheck: json['sequencecheck'] as int?,
      flagged: json['flagged'] as bool?,
      state: json['state'] as String?,
      mark: json['mark'] as String?,
    );
  }
}
