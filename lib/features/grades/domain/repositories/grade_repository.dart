import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/grade.dart';

abstract class GradeRepository {
  Future<Either<Failure, List<GradeItem>>> getGradeItems(
    int courseId,
    int userId,
  );
  Future<Either<Failure, List<CourseGrade>>> getCourseGrades(int userId);
}
