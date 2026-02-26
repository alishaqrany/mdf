import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/course.dart';

abstract class CoursesRepository {
  Future<Either<Failure, List<Course>>> getEnrolledCourses(int userId);
  Future<Either<Failure, List<Course>>> getRecentCourses(int userId);
  Future<Either<Failure, List<Course>>> searchCourses(String query);
  Future<Either<Failure, List<Course>>> getAllCourses();
  Future<Either<Failure, List<CourseCategory>>> getCategories();
  Future<Either<Failure, Course>> getCourseById(int courseId);
}
