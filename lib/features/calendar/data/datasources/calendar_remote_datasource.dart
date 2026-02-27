import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/calendar_event_model.dart';

abstract class CalendarRemoteDataSource {
  Future<List<CalendarEventModel>> getCalendarEvents({
    int? courseId,
    int? timeStart,
    int? timeEnd,
  });

  Future<List<CalendarEventModel>> getUpcomingEvents();
}

class CalendarRemoteDataSourceImpl implements CalendarRemoteDataSource {
  final MoodleApiClient apiClient;

  CalendarRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CalendarEventModel>> getCalendarEvents({
    int? courseId,
    int? timeStart,
    int? timeEnd,
  }) async {
    try {
      final params = <String, dynamic>{
        'options[userevents]': 1,
        'options[siteevents]': 1,
      };
      if (courseId != null) {
        params['events[courseids][0]'] = courseId;
      }
      if (timeStart != null) {
        params['options[timestart]'] = timeStart;
      }
      if (timeEnd != null) {
        params['options[timeend]'] = timeEnd;
      }

      final response = await apiClient.call(
        MoodleApiEndpoints.getCalendarEvents,
        params: params,
      );

      if (response is Map && response.containsKey('events')) {
        return (response['events'] as List)
            .map((j) => CalendarEventModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<CalendarEventModel>> getUpcomingEvents() async {
    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getCalendarUpcomingView,
      );

      if (response is Map && response.containsKey('events')) {
        return (response['events'] as List)
            .map((j) => CalendarEventModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
