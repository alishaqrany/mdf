import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/courses_repository.dart';

class GetCourseContentsUseCase {
  final CoursesRepository repository;
  GetCourseContentsUseCase(this.repository);

  // This use case delegates to the course content repository
  // but provides a unified interface
  Future<Either<Failure, dynamic>> call(int courseId) async {
    return repository.getCourseById(courseId);
  }
}
