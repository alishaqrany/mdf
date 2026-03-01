import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gamification_entities.dart';
import '../../domain/repositories/gamification_repository.dart';

// ─── Events ───

abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadLeaderboard extends LeaderboardEvent {
  final LeaderboardPeriod period;
  final int? courseId;
  final int limit;

  const LoadLeaderboard({
    this.period = LeaderboardPeriod.allTime,
    this.courseId,
    this.limit = 50,
  });

  @override
  List<Object?> get props => [period, courseId, limit];
}

class ChangePeriod extends LeaderboardEvent {
  final LeaderboardPeriod period;
  const ChangePeriod(this.period);
  @override
  List<Object?> get props => [period];
}

// ─── States ───

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();
  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {}

class LeaderboardLoading extends LeaderboardState {}

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardPeriod period;
  final LeaderboardEntry? currentUser;

  const LeaderboardLoaded({
    required this.entries,
    required this.period,
    this.currentUser,
  });

  @override
  List<Object?> get props => [entries, period, currentUser];
}

class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final GamificationRepository repository;
  int? _courseId;

  LeaderboardBloc({required this.repository}) : super(LeaderboardInitial()) {
    on<LoadLeaderboard>(_onLoad);
    on<ChangePeriod>(_onChangePeriod);
  }

  Future<void> _onLoad(
    LoadLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoading());
    _courseId = event.courseId;
    final result = await repository.getLeaderboard(
      period: event.period,
      courseId: event.courseId,
      limit: event.limit,
    );
    result.fold(
      (failure) => emit(LeaderboardError(failure.message)),
      (entries) {
        final currentUser = entries
            .where((e) => e.isCurrentUser)
            .toList();
        emit(LeaderboardLoaded(
          entries: entries,
          period: event.period,
          currentUser: currentUser.isNotEmpty ? currentUser.first : null,
        ));
      },
    );
  }

  void _onChangePeriod(
    ChangePeriod event,
    Emitter<LeaderboardState> emit,
  ) {
    add(LoadLeaderboard(period: event.period, courseId: _courseId));
  }
}
