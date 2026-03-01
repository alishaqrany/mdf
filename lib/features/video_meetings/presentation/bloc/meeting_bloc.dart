import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/meeting.dart';
import '../../domain/repositories/meeting_repository.dart';
import 'meeting_event.dart';
import 'meeting_state.dart';

class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final MeetingRepository repository;

  // Cache the meeting list so we can find a specific meeting for detail view.
  List<Meeting> _cachedMeetings = [];

  MeetingBloc({required this.repository}) : super(MeetingInitial()) {
    on<LoadMeetings>(_onLoadMeetings);
    on<LoadMeetingInfo>(_onLoadMeetingInfo);
    on<ViewMeeting>(_onViewMeeting);
  }

  Future<void> _onLoadMeetings(
    LoadMeetings event,
    Emitter<MeetingState> emit,
  ) async {
    emit(MeetingLoading());
    final result = await repository.getMeetings(event.courseIds);
    result.fold((failure) => emit(MeetingError(message: failure.message)), (
      meetings,
    ) {
      _cachedMeetings = meetings;
      // Sort: open first, then upcoming, then ended.
      meetings.sort((a, b) {
        if (a.isOpen && !b.isOpen) return -1;
        if (!a.isOpen && b.isOpen) return 1;
        if (a.isUpcoming && !b.isUpcoming) return -1;
        if (!a.isUpcoming && b.isUpcoming) return 1;
        return (b.openingTime ?? 0).compareTo(a.openingTime ?? 0);
      });
      emit(MeetingsLoaded(meetings: meetings));
    });
  }

  Future<void> _onLoadMeetingInfo(
    LoadMeetingInfo event,
    Emitter<MeetingState> emit,
  ) async {
    emit(MeetingLoading());

    // Find the meeting from cache
    final meeting = _cachedMeetings.firstWhere(
      (m) => m.id == event.meetingId,
      orElse: () => Meeting(
        id: event.meetingId,
        courseId: 0,
        courseModule: event.cmId,
        name: '',
        timeModified: 0,
      ),
    );

    final result = await repository.getMeetingInfo(event.meetingId);
    result.fold(
      (failure) => emit(MeetingError(message: failure.message)),
      (info) => emit(MeetingInfoLoaded(meeting: meeting, info: info)),
    );
  }

  Future<void> _onViewMeeting(
    ViewMeeting event,
    Emitter<MeetingState> emit,
  ) async {
    await repository.viewMeeting(event.meetingId);
  }
}
