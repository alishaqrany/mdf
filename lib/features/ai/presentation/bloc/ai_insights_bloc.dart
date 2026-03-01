import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_repository.dart';

// ─── Events ───
abstract class AiEvent extends Equatable {
  const AiEvent();
  @override
  List<Object?> get props => [];
}

class LoadStudentInsights extends AiEvent {
  final int userId;
  const LoadStudentInsights({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadRecommendations extends AiEvent {
  final int userId;
  const LoadRecommendations({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadPerformancePredictions extends AiEvent {
  final int userId;
  const LoadPerformancePredictions({required this.userId});
  @override
  List<Object?> get props => [userId];
}

// ─── States ───
abstract class AiInsightsState extends Equatable {
  const AiInsightsState();
  @override
  List<Object?> get props => [];
}

class AiInsightsInitial extends AiInsightsState {}

class AiInsightsLoading extends AiInsightsState {}

class AiInsightsLoaded extends AiInsightsState {
  final StudentInsights insights;
  const AiInsightsLoaded({required this.insights});
  @override
  List<Object?> get props => [insights];
}

class AiInsightsError extends AiInsightsState {
  final String message;
  const AiInsightsError({required this.message});
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ───
class AiInsightsBloc extends Bloc<AiEvent, AiInsightsState> {
  final AiRepository repository;

  AiInsightsBloc({required this.repository}) : super(AiInsightsInitial()) {
    on<LoadStudentInsights>(_onLoadInsights);
  }

  Future<void> _onLoadInsights(
    LoadStudentInsights event,
    Emitter<AiInsightsState> emit,
  ) async {
    emit(AiInsightsLoading());
    final result = await repository.getStudentInsights(event.userId);
    result.fold(
      (failure) => emit(AiInsightsError(message: failure.message)),
      (insights) => emit(AiInsightsLoaded(insights: insights)),
    );
  }
}
