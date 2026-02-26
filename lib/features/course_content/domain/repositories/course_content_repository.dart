import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/course_content.dart';

abstract class CourseContentRepository {
  Future<Either<Failure, List<CourseSection>>> getCourseContents(int courseId);
  Future<Either<Failure, void>> updateActivityCompletion(
    int cmId,
    bool completed,
  );
}
