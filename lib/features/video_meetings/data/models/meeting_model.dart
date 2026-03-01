import '../../domain/entities/meeting.dart';

class MeetingModel extends Meeting {
  const MeetingModel({
    required super.id,
    required super.courseId,
    required super.courseModule,
    required super.name,
    super.intro,
    super.openingTime,
    super.closingTime,
    super.type,
    required super.timeModified,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'] ?? 0,
      courseId: json['course'] ?? json['courseid'] ?? 0,
      courseModule: json['coursemodule'] ?? json['cmid'] ?? 0,
      name: json['name'] ?? '',
      intro: _stripHtml(json['intro'] ?? ''),
      openingTime: json['openingtime'] ?? json['timeopen'] ?? 0,
      closingTime: json['closingtime'] ?? json['timeclose'] ?? 0,
      type: _parseType(json['type']),
      timeModified: json['timemodified'] ?? 0,
    );
  }

  static MeetingType _parseType(dynamic t) {
    final val = t is int ? t : int.tryParse(t?.toString() ?? '') ?? 0;
    switch (val) {
      case 1:
        return MeetingType.roomOnly;
      case 2:
        return MeetingType.recording;
      default:
        return MeetingType.roomActivity;
    }
  }

  static String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }
}

class MeetingInfoModel extends MeetingInfo {
  const MeetingInfoModel({
    required super.canJoin,
    required super.isRunning,
    super.joinUrl,
    super.participantCount,
    super.moderatorCount,
    super.recordings,
  });

  factory MeetingInfoModel.fromJson(Map<String, dynamic> json) {
    final recordings = <MeetingRecordingModel>[];

    // Recordings may come in different structures
    if (json['recordings'] is List) {
      for (final r in json['recordings']) {
        recordings.add(MeetingRecordingModel.fromJson(r));
      }
    } else if (json['tabledata'] is Map) {
      // Alternative recording format in some Moodle versions
      final table = json['tabledata'];
      if (table['data'] is List) {
        for (final row in table['data']) {
          if (row is Map && row['playback'] != null) {
            recordings.add(
              MeetingRecordingModel(
                recordingId: row['recordingid']?.toString() ?? '',
                name: row['recording']?.toString(),
                playbackUrl: row['playback']?.toString(),
                published: true,
              ),
            );
          }
        }
      }
    }

    return MeetingInfoModel(
      canJoin: json['canjoin'] == true || json['canjoin'] == 1,
      isRunning: json['cmid'] != null
          ? true
          : (json['isrunning'] == true || json['isrunning'] == 1),
      joinUrl: json['joinurl'] ?? json['join_url'],
      participantCount: json['participantcount'] ?? json['participantCount'],
      moderatorCount: json['moderatorcount'] ?? json['moderatorCount'],
      recordings: recordings,
    );
  }
}

class MeetingRecordingModel extends MeetingRecording {
  const MeetingRecordingModel({
    required super.recordingId,
    super.name,
    super.description,
    super.playbackUrl,
    super.startTime,
    super.endTime,
    super.published,
  });

  factory MeetingRecordingModel.fromJson(Map<String, dynamic> json) {
    return MeetingRecordingModel(
      recordingId:
          json['recordingid']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? json['meetingname'],
      description: json['description'],
      playbackUrl: json['playbackurl'] ?? json['playback_url'] ?? json['url'],
      startTime: json['starttime'] ?? json['start_time'],
      endTime: json['endtime'] ?? json['end_time'],
      published: json['published'] != false && json['published'] != 0,
    );
  }
}
