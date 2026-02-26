import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/course.dart';
import '../repositories/courses_repository.dart';

class SearchCoursesUseCase {
  final CoursesRepository repository;
  SearchCoursesUseCase(this.repository);

  Future<Either<Failure, List<Course>>> call(String query) {
    return repository.searchCourses(query);
  }
}
