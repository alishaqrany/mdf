import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meeting.dart';

/// Repository for video meetings (BigBlueButton).
abstract class MeetingRepository {
  /// Get all BBB instances for a list of course IDs.
  Future<Either<Failure, List<Meeting>>> getMeetings(List<int> courseIds);

  /// Get live meeting info — whether it's running, join URL, recordings, etc.
  Future<Either<Failure, MeetingInfo>> getMeetingInfo(int cmId);

  /// Mark the BBB activity as viewed.
  Future<Either<Failure, void>> viewMeeting(int meetingId);
}
