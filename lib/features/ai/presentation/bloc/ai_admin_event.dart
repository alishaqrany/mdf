part of 'ai_admin_bloc.dart';

abstract class AiAdminEvent extends Equatable {
  const AiAdminEvent();
  @override
  List<Object?> get props => [];
}

class LoadAiAdminData extends AiAdminEvent {
  const LoadAiAdminData();
}

class SaveAiProviderConfig extends AiAdminEvent {
  final AiConfigModel config;
  const SaveAiProviderConfig({required this.config});
  @override
  List<Object?> get props => [config.provider, config.enabled];
}

class LoadAiUsageStats extends AiAdminEvent {
  final int days;
  const LoadAiUsageStats({this.days = 30});
  @override
  List<Object?> get props => [days];
}

class SetAiUserLimits extends AiAdminEvent {
  final int userid;
  final int dailylimit;
  final int monthlylimit;

  const SetAiUserLimits({
    this.userid = 0,
    required this.dailylimit,
    required this.monthlylimit,
  });

  @override
  List<Object?> get props => [userid, dailylimit, monthlylimit];
}

class LoadAiChatHistory extends AiAdminEvent {
  final int? userid;
  final int limit;

  const LoadAiChatHistory({this.userid, this.limit = 50});

  @override
  List<Object?> get props => [userid, limit];
}
