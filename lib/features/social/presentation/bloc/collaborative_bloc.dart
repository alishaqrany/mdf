import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/social_entities.dart';
import '../../domain/repositories/social_repository.dart';

// ─── Events ───
abstract class CollaborativeEvent extends Equatable {
  const CollaborativeEvent();
  @override
  List<Object?> get props => [];
}

class LoadGroupSessions extends CollaborativeEvent {
  final int groupId;
  const LoadGroupSessions(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

class CreateSession extends CollaborativeEvent {
  final String title;
  final int groupId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? description;
  final String? topic;

  const CreateSession({
    required this.title,
    required this.groupId,
    required this.startTime,
    this.endTime,
    this.description,
    this.topic,
  });

  @override
  List<Object?> get props => [title, groupId, startTime];
}

class JoinSession extends CollaborativeEvent {
  final int sessionId;
  const JoinSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class LeaveSession extends CollaborativeEvent {
  final int sessionId;
  const LeaveSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class EndSession extends CollaborativeEvent {
  final int sessionId;
  const EndSession(this.sessionId);
  @override
  List<Object?> get props => [sessionId];
}

class AddSessionNoteEvent extends CollaborativeEvent {
  final int sessionId;
  final String content;
  const AddSessionNoteEvent({required this.sessionId, required this.content});
  @override
  List<Object?> get props => [sessionId, content];
}

// ─── States ───
abstract class CollaborativeState extends Equatable {
  const CollaborativeState();
  @override
  List<Object?> get props => [];
}

class CollaborativeInitial extends CollaborativeState {}

class CollaborativeLoading extends CollaborativeState {}

class CollaborativeSessionsLoaded extends CollaborativeState {
  final List<CollaborativeSession> sessions;
  const CollaborativeSessionsLoaded(this.sessions);
  @override
  List<Object?> get props => [sessions];
}

class CollaborativeSessionCreated extends CollaborativeState {
  final CollaborativeSession session;
  const CollaborativeSessionCreated(this.session);
  @override
  List<Object?> get props => [session];
}

class CollaborativeActionSuccess extends CollaborativeState {
  final String action;
  const CollaborativeActionSuccess(this.action);
  @override
  List<Object?> get props => [action];
}

class CollaborativeError extends CollaborativeState {
  final String message;
  const CollaborativeError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class CollaborativeBloc extends Bloc<CollaborativeEvent, CollaborativeState> {
  final SocialRepository repository;

  CollaborativeBloc({required this.repository})
    : super(CollaborativeInitial()) {
    on<LoadGroupSessions>(_onLoadSessions);
    on<CreateSession>(_onCreateSession);
    on<JoinSession>(_onJoinSession);
    on<LeaveSession>(_onLeaveSession);
    on<EndSession>(_onEndSession);
    on<AddSessionNoteEvent>(_onAddNote);
  }

  Future<void> _onLoadSessions(
    LoadGroupSessions event,
    Emitter<CollaborativeState> emit,
  ) async {
    emit(CollaborativeLoading());
    final result = await repository.getGroupSessions(event.groupId);
    result.fold(
      (f) => emit(CollaborativeError(f.message)),
      (sessions) => emit(CollaborativeSessionsLoaded(sessions)),
    );
  }

  Future<void> _onCreateSession(
    CreateSession event,
    Emitter<CollaborativeState> emit,
  ) async {
    emit(CollaborativeLoading());
    final result = await repository.createSession(
      title: event.title,
      groupId: event.groupId,
      startTime: event.startTime,
      endTime: event.endTime,
      description: event.description,
      topic: event.topic,
    );
    result.fold(
      (f) => emit(CollaborativeError(f.message)),
      (session) => emit(CollaborativeSessionCreated(session)),
    );
  }

  Future<void> _onJoinSession(
    JoinSession event,
    Emitter<CollaborativeState> emit,
  ) async {
    final result = await repository.joinSession(event.sessionId);
    result.fold(
      (f) => emit(CollaborativeError(f.message)),
      (_) => emit(const CollaborativeActionSuccess('joined')),
    );
  }

  Future<void> _onLeaveSession(
    LeaveSession event,
    Emitter<CollaborativeState> emit,
  ) async {
    final result = await repository.leaveSession(event.sessionId);
    result.fold(
      (f) => emit(CollaborativeError(f.message)),
      (_) => emit(const CollaborativeActionSuccess('left')),
    );
  }

  Future<void> _onEndSession(
    EndSession event,
    Emitter<CollaborativeState> emit,
  ) async {
    final result = await repository.endSession(event.sessionId);
    result.fold(
      (f) => emit(CollaborativeError(f.message)),
      (_) => emit(const CollaborativeActionSuccess('ended')),
    );
  }

  Future<void> _onAddNote(
    AddSessionNoteEvent event,
    Emitter<CollaborativeState> emit,
  ) async {
    final result = await repository.addSessionNote(
      event.sessionId,
      event.content,
    );
    result.fold(
      (f) => emit(CollaborativeError(f.message)),
      (_) => emit(const CollaborativeActionSuccess('note_added')),
    );
  }
}
