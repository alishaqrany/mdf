import 'dart:developer' as dev;

import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/meeting_model.dart';

abstract class MeetingRemoteDataSource {
  Future<List<MeetingModel>> getMeetings(List<int> courseIds);
  Future<MeetingInfoModel> getMeetingInfo(int cmId);
  Future<void> viewMeeting(int meetingId);
}

class MeetingRemoteDataSourceImpl implements MeetingRemoteDataSource {
  final MoodleApiClient apiClient;

  MeetingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<MeetingModel>> getMeetings(List<int> courseIds) async {
    final params = <String, dynamic>{};
    for (int i = 0; i < courseIds.length; i++) {
      params['courseids[$i]'] = courseIds[i];
    }

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getBBBInstances,
        params: params,
      );

      dev.log('getBBBInstances response type: ${response.runtimeType}');

      List<dynamic>? instanceList;

      if (response is Map && response.containsKey('bigbluebuttonbns')) {
        instanceList = response['bigbluebuttonbns'] as List?;
      } else if (response is List) {
        instanceList = response;
      }

      if (instanceList != null) {
        return instanceList
            .map((j) => MeetingModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      dev.log('getMeetings error: $e\n$st');
      rethrow;
    }
    return [];
  }

  @override
  Future<MeetingInfoModel> getMeetingInfo(int cmId) async {
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getBBBMeetingInfo,
        params: {'bigbluebuttonbnid': cmId},
      );

      dev.log('getBBBMeetingInfo response type: ${response.runtimeType}');

      if (response is Map<String, dynamic>) {
        return MeetingInfoModel.fromJson(response);
      }

      // Fallback — if the response doesn't parse well, return a default
      return const MeetingInfoModel(
        canJoin: false,
        isRunning: false,
        recordings: [],
      );
    } catch (e, st) {
      dev.log('getMeetingInfo error: $e\n$st');
      rethrow;
    }
  }

  @override
  Future<void> viewMeeting(int meetingId) async {
    try {
      await apiClient.call(
        MoodleApiEndpoints.viewBBB,
        params: {'bigbluebuttonbnid': meetingId},
      );
    } catch (e) {
      dev.log('viewMeeting error: $e');
      // Non-critical — don't rethrow
    }
  }
}
