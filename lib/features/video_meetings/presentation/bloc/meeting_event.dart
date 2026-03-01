import 'package:equatable/equatable.dart';

abstract class MeetingEvent extends Equatable {
  const MeetingEvent();

  @override
  List<Object?> get props => [];
}

/// Load all BBB meetings for given course IDs.
class LoadMeetings extends MeetingEvent {
  final List<int> courseIds;

  const LoadMeetings({required this.courseIds});

  @override
  List<Object?> get props => [courseIds];
}

/// Load meeting info (join URL, recording, running status) for a specific BBB instance.
class LoadMeetingInfo extends MeetingEvent {
  final int meetingId; // BBB instance ID
  final int cmId; // Course module ID

  const LoadMeetingInfo({required this.meetingId, required this.cmId});

  @override
  List<Object?> get props => [meetingId, cmId];
}

/// Mark as viewed.
class ViewMeeting extends MeetingEvent {
  final int meetingId;

  const ViewMeeting({required this.meetingId});

  @override
  List<Object?> get props => [meetingId];
}
