import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/models/ai_config_model.dart';
import '../../data/models/ai_message_model.dart';
import '../../data/models/ai_usage_model.dart';

part 'ai_admin_event.dart';
part 'ai_admin_state.dart';

class AiAdminBloc extends Bloc<AiAdminEvent, AiAdminState> {
  final AiRemoteDataSource dataSource;

  AiAdminBloc({required this.dataSource}) : super(AiAdminInitial()) {
    on<LoadAiAdminData>(_onLoad);
    on<SaveAiProviderConfig>(_onSaveConfig);
    on<LoadAiUsageStats>(_onLoadStats);
    on<SetAiUserLimits>(_onSetLimits);
    on<LoadAiChatHistory>(_onLoadHistory);
  }

  Future<void> _onLoad(
    LoadAiAdminData event,
    Emitter<AiAdminState> emit,
  ) async {
    emit(AiAdminLoading());
    try {
      final configs = await dataSource.getAiConfigs();
      final stats = await dataSource.getAiUsageStats();
      final limits = await dataSource.getAiUserLimit(userid: 0);

      emit(
        AiAdminLoaded(configs: configs, stats: stats, defaultLimits: limits),
      );
    } catch (e) {
      emit(AiAdminError(message: e.toString()));
    }
  }

  Future<void> _onSaveConfig(
    SaveAiProviderConfig event,
    Emitter<AiAdminState> emit,
  ) async {
    try {
      await dataSource.saveAiConfig(event.config);
      // Reload all
      add(const LoadAiAdminData());
    } catch (e) {
      emit(AiAdminError(message: 'Failed to save config: $e'));
    }
  }

  Future<void> _onLoadStats(
    LoadAiUsageStats event,
    Emitter<AiAdminState> emit,
  ) async {
    try {
      final stats = await dataSource.getAiUsageStats(days: event.days);
      final currentState = state;
      if (currentState is AiAdminLoaded) {
        emit(currentState.copyWith(stats: stats));
      }
    } catch (e) {
      emit(AiAdminError(message: 'Failed to load stats: $e'));
    }
  }

  Future<void> _onSetLimits(
    SetAiUserLimits event,
    Emitter<AiAdminState> emit,
  ) async {
    try {
      await dataSource.setAiUserLimit(
        userid: event.userid,
        dailylimit: event.dailylimit,
        monthlylimit: event.monthlylimit,
      );
      // Reload
      add(const LoadAiAdminData());
    } catch (e) {
      emit(AiAdminError(message: 'Failed to set limits: $e'));
    }
  }

  Future<void> _onLoadHistory(
    LoadAiChatHistory event,
    Emitter<AiAdminState> emit,
  ) async {
    try {
      final messages = await dataSource.getChatHistory(
        userid: event.userid,
        limit: event.limit,
      );
      final currentState = state;
      if (currentState is AiAdminLoaded) {
        emit(currentState.copyWith(chatHistory: messages));
      } else {
        emit(AiAdminChatHistoryLoaded(messages: messages));
      }
    } catch (e) {
      emit(AiAdminError(message: 'Failed to load history: $e'));
    }
  }
}
