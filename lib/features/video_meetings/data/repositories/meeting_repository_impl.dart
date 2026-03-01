import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/meeting_remote_datasource.dart';

class MeetingRepositoryImpl implements MeetingRepository {
  final MeetingRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MeetingRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Meeting>>> getMeetings(
    List<int> courseIds,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final meetings = await remoteDataSource.getMeetings(courseIds);
      return Right(meetings);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MeetingInfo>> getMeetingInfo(int cmId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final info = await remoteDataSource.getMeetingInfo(cmId);
      return Right(info);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> viewMeeting(int meetingId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.viewMeeting(meetingId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
