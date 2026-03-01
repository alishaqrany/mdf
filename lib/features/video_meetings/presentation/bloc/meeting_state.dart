import 'package:equatable/equatable.dart';

import '../../domain/entities/meeting.dart';

abstract class MeetingState extends Equatable {
  const MeetingState();

  @override
  List<Object?> get props => [];
}

class MeetingInitial extends MeetingState {}

class MeetingLoading extends MeetingState {}

class MeetingsLoaded extends MeetingState {
  final List<Meeting> meetings;

  const MeetingsLoaded({required this.meetings});

  @override
  List<Object?> get props => [meetings];
}

class MeetingInfoLoaded extends MeetingState {
  final Meeting meeting;
  final MeetingInfo info;

  const MeetingInfoLoaded({required this.meeting, required this.info});

  @override
  List<Object?> get props => [meeting, info];
}

class MeetingError extends MeetingState {
  final String message;

  const MeetingError({required this.message});

  @override
  List<Object?> get props => [message];
}
