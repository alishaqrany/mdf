import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/gamification_entities.dart';
import '../../domain/repositories/gamification_repository.dart';

// ─── Events ───

abstract class PointsEvent extends Equatable {
  const PointsEvent();
  @override
  List<Object?> get props => [];
}

class LoadUserPoints extends PointsEvent {
  final int userId;
  const LoadUserPoints(this.userId);
  @override
  List<Object?> get props => [userId];
}

class LoadPointHistory extends PointsEvent {
  final int userId;
  const LoadPointHistory(this.userId);
  @override
  List<Object?> get props => [userId];
}

class RecordDailyLogin extends PointsEvent {
  final int userId;
  const RecordDailyLogin(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ─── States ───

abstract class PointsState extends Equatable {
  const PointsState();
  @override
  List<Object?> get props => [];
}

class PointsInitial extends PointsState {}

class PointsLoading extends PointsState {}

class PointsLoaded extends PointsState {
  final UserPoints userPoints;
  final List<PointTransaction> history;

  const PointsLoaded({required this.userPoints, this.history = const []});

  @override
  List<Object?> get props => [userPoints, history];
}

class PointsError extends PointsState {
  final String message;
  const PointsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───

class PointsBloc extends Bloc<PointsEvent, PointsState> {
  final GamificationRepository repository;

  PointsBloc({required this.repository}) : super(PointsInitial()) {
    on<LoadUserPoints>(_onLoadUserPoints);
    on<LoadPointHistory>(_onLoadPointHistory);
    on<RecordDailyLogin>(_onRecordDailyLogin);
  }

  Future<void> _onLoadUserPoints(
    LoadUserPoints event,
    Emitter<PointsState> emit,
  ) async {
    emit(PointsLoading());
    final result = await repository.getUserPoints(event.userId);
    result.fold(
      (failure) => emit(PointsError(failure.message)),
      (points) => emit(PointsLoaded(userPoints: points)),
    );
  }

  Future<void> _onLoadPointHistory(
    LoadPointHistory event,
    Emitter<PointsState> emit,
  ) async {
    final pointsResult = await repository.getUserPoints(event.userId);
    final historyResult = await repository.getPointHistory(event.userId);

    pointsResult.fold(
      (failure) => emit(PointsError(failure.message)),
      (points) {
        historyResult.fold(
          (failure) => emit(PointsLoaded(userPoints: points)),
          (history) =>
              emit(PointsLoaded(userPoints: points, history: history)),
        );
      },
    );
  }

  Future<void> _onRecordDailyLogin(
    RecordDailyLogin event,
    Emitter<PointsState> emit,
  ) async {
    final result = await repository.recordDailyLogin(event.userId);
    result.fold(
      (failure) => null,
      (points) {
        final currentState = state;
        if (currentState is PointsLoaded) {
          emit(PointsLoaded(
            userPoints: points,
            history: currentState.history,
          ));
        } else {
          emit(PointsLoaded(userPoints: points));
        }
      },
    );
  }
}
