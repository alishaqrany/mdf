import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/assignment.dart';

abstract class AssignmentRepository {
  Future<Either<Failure, List<Assignment>>> getAssignmentsByCourse(
    int courseId,
  );
  Future<Either<Failure, List<AssignmentSubmission>>> getSubmissions(
    int assignmentId,
  );
  Future<Either<Failure, List<AssignmentGrade>>> getGrades(
    int assignmentId,
  );
  Future<Either<Failure, void>> saveSubmission(
    int assignmentId,
    String? onlineText,
    int? fileItemId,
  );
  Future<Either<Failure, void>> submitForGrading(int assignmentId);
}
