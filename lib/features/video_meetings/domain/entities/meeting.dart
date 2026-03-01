import 'package:equatable/equatable.dart';

/// Represents a BigBlueButton meeting instance in a course.
class Meeting extends Equatable {
  final int id;
  final int courseId;
  final int courseModule; // cmid
  final String name;
  final String? intro;
  final int? openingTime; // Unix timestamp
  final int? closingTime; // Unix timestamp
  final MeetingType type;
  final int timeModified;

  const Meeting({
    required this.id,
    required this.courseId,
    required this.courseModule,
    required this.name,
    this.intro,
    this.openingTime,
    this.closingTime,
    this.type = MeetingType.roomActivity,
    required this.timeModified,
  });

  /// Computed: whether the meeting is currently open.
  bool get isOpen {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final opened =
        openingTime == null || openingTime == 0 || now >= openingTime!;
    final notClosed =
        closingTime == null || closingTime == 0 || now <= closingTime!;
    return opened && notClosed;
  }

  /// Is the meeting scheduled in the future?
  bool get isUpcoming {
    if (openingTime == null || openingTime == 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now < openingTime!;
  }

  /// Has the meeting already ended?
  bool get hasEnded {
    if (closingTime == null || closingTime == 0) return false;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now > closingTime!;
  }

  DateTime? get openingDateTime => openingTime != null && openingTime! > 0
      ? DateTime.fromMillisecondsSinceEpoch(openingTime! * 1000)
      : null;

  DateTime? get closingDateTime => closingTime != null && closingTime! > 0
      ? DateTime.fromMillisecondsSinceEpoch(closingTime! * 1000)
      : null;

  @override
  List<Object?> get props => [id, courseId, name];
}

/// BBB activity type constants.
enum MeetingType {
  roomActivity, // 0 — Room with activity
  roomOnly, // 1 — Room only
  recording, // 2 — Recordings only
}

/// Live meeting info from the server.
class MeetingInfo extends Equatable {
  final bool canJoin;
  final bool isRunning;
  final String? joinUrl;
  final int? participantCount;
  final int? moderatorCount;
  final List<MeetingRecording> recordings;

  const MeetingInfo({
    required this.canJoin,
    required this.isRunning,
    this.joinUrl,
    this.participantCount,
    this.moderatorCount,
    this.recordings = const [],
  });

  @override
  List<Object?> get props => [canJoin, isRunning, joinUrl];
}

/// A BBB recording.
class MeetingRecording extends Equatable {
  final String recordingId;
  final String? name;
  final String? description;
  final String? playbackUrl;
  final int? startTime;
  final int? endTime;
  final bool published;

  const MeetingRecording({
    required this.recordingId,
    this.name,
    this.description,
    this.playbackUrl,
    this.startTime,
    this.endTime,
    this.published = true,
  });

  DateTime? get startDateTime => startTime != null && startTime! > 0
      ? DateTime.fromMillisecondsSinceEpoch(startTime! * 1000)
      : null;

  @override
  List<Object?> get props => [recordingId, playbackUrl];
}
