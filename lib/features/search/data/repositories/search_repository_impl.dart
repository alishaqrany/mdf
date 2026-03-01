import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<SearchResult>>> searchCourses(
    String query,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final results = await remoteDataSource.searchCourses(query);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchUsers(String query) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final results = await remoteDataSource.searchUsers(query);
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SearchResult>>> searchAll(String query) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final futures = await Future.wait([
        remoteDataSource.searchCourses(query),
        remoteDataSource.searchUsers(query),
      ]);
      final all = <SearchResult>[...futures[0], ...futures[1]];
      return Right(all);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
