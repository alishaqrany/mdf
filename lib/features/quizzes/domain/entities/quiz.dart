import 'package:equatable/equatable.dart';

/// Represents a Moodle quiz.
class Quiz extends Equatable {
  final int id;
  final int courseId;
  final String name;
  final String? intro;
  final int? timeOpen;
  final int? timeClose;
  final int? timeLimit;
  final int? attempts;
  final String? gradeMethod; // 1=highest,2=avg,3=first,4=last
  final double? grade;
  final bool? hasQuestions;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.name,
    this.intro,
    this.timeOpen,
    this.timeClose,
    this.timeLimit,
    this.attempts,
    this.gradeMethod,
    this.grade,
    this.hasQuestions,
  });

  @override
  List<Object?> get props => [id, courseId, name];
}

/// A quiz attempt.
class QuizAttempt extends Equatable {
  final int id;
  final int quizId;
  final int userId;
  final int attempt;
  final String state; // inprogress, finished, overdue, abandoned
  final int? timeStart;
  final int? timeFinish;
  final int? timeModified;
  final double? sumGrades;

  const QuizAttempt({
    required this.id,
    required this.quizId,
    required this.userId,
    required this.attempt,
    required this.state,
    this.timeStart,
    this.timeFinish,
    this.timeModified,
    this.sumGrades,
  });

  bool get isInProgress => state == 'inprogress';
  bool get isFinished => state == 'finished';

  @override
  List<Object?> get props => [id, quizId, attempt];
}

/// A question in a quiz attempt.
class QuizQuestion extends Equatable {
  final int slot;
  final String type;
  final String html;
  final int? sequenceCheck;
  final bool? flagged;
  final String? state;
  final String? mark;

  const QuizQuestion({
    required this.slot,
    required this.type,
    required this.html,
    this.sequenceCheck,
    this.flagged,
    this.state,
    this.mark,
  });

  @override
  List<Object?> get props => [slot, type];
}

/// Quiz attempt review data.
class QuizReview extends Equatable {
  final QuizAttempt attempt;
  final List<QuizQuestion> questions;
  final double? grade;
  final List<Map<String, dynamic>>? additionalData;

  const QuizReview({
    required this.attempt,
    required this.questions,
    this.grade,
    this.additionalData,
  });

  @override
  List<Object?> get props => [attempt, questions];
}
