import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/search_result.dart';

abstract class SearchRepository {
  Future<Either<Failure, List<SearchResult>>> searchCourses(String query);
  Future<Either<Failure, List<SearchResult>>> searchUsers(String query);
  Future<Either<Failure, List<SearchResult>>> searchAll(String query);
}
