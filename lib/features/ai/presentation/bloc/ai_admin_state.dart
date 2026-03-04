part of 'ai_admin_bloc.dart';

abstract class AiAdminState extends Equatable {
  const AiAdminState();
  @override
  List<Object?> get props => [];
}

class AiAdminInitial extends AiAdminState {}

class AiAdminLoading extends AiAdminState {}

class AiAdminLoaded extends AiAdminState {
  final List<AiConfigModel> configs;
  final AiUsageStatsModel stats;
  final AiUserLimitModel defaultLimits;
  final List<AiMessageModel>? chatHistory;

  const AiAdminLoaded({
    required this.configs,
    required this.stats,
    required this.defaultLimits,
    this.chatHistory,
  });

  AiAdminLoaded copyWith({
    List<AiConfigModel>? configs,
    AiUsageStatsModel? stats,
    AiUserLimitModel? defaultLimits,
    List<AiMessageModel>? chatHistory,
  }) {
    return AiAdminLoaded(
      configs: configs ?? this.configs,
      stats: stats ?? this.stats,
      defaultLimits: defaultLimits ?? this.defaultLimits,
      chatHistory: chatHistory ?? this.chatHistory,
    );
  }

  @override
  List<Object?> get props => [configs, stats, defaultLimits, chatHistory];
}

class AiAdminChatHistoryLoaded extends AiAdminState {
  final List<AiMessageModel> messages;
  const AiAdminChatHistoryLoaded({required this.messages});
  @override
  List<Object?> get props => [messages];
}

class AiAdminError extends AiAdminState {
  final String message;
  const AiAdminError({required this.message});
  @override
  List<Object?> get props => [message];
}
