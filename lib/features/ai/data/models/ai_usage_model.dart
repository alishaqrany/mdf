/// Aggregated AI usage statistics.
class AiUsageStatsModel {
  final int totalmessages;
  final int totaltokens;
  final int uniqueusers;
  final List<ProviderStat> providers;
  final List<TopUserStat> topUsers;

  const AiUsageStatsModel({
    required this.totalmessages,
    required this.totaltokens,
    required this.uniqueusers,
    this.providers = const [],
    this.topUsers = const [],
  });

  factory AiUsageStatsModel.fromJson(Map<String, dynamic> json) {
    return AiUsageStatsModel(
      totalmessages: json['totalmessages'] as int? ?? 0,
      totaltokens: json['totaltokens'] as int? ?? 0,
      uniqueusers: json['uniqueusers'] as int? ?? 0,
      providers: (json['providers'] as List? ?? [])
          .map((e) => ProviderStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      topUsers: (json['topusers'] as List? ?? [])
          .map((e) => TopUserStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ProviderStat {
  final String provider;
  final int messages;
  final int tokens;

  const ProviderStat({
    required this.provider,
    required this.messages,
    required this.tokens,
  });

  factory ProviderStat.fromJson(Map<String, dynamic> json) {
    return ProviderStat(
      provider: json['provider'] as String? ?? '',
      messages: json['messages'] as int? ?? 0,
      tokens: json['tokens'] as int? ?? 0,
    );
  }
}

class TopUserStat {
  final int userid;
  final String fullname;
  final int messages;
  final int tokens;

  const TopUserStat({
    required this.userid,
    required this.fullname,
    required this.messages,
    required this.tokens,
  });

  factory TopUserStat.fromJson(Map<String, dynamic> json) {
    return TopUserStat(
      userid: json['userid'] as int? ?? 0,
      fullname: json['fullname'] as String? ?? 'Unknown',
      messages: json['messages'] as int? ?? 0,
      tokens: json['tokens'] as int? ?? 0,
    );
  }
}

/// Per-user AI usage limits.
class AiUserLimitModel {
  final int userid;
  final int dailylimit;
  final int monthlylimit;
  final int dailycount;
  final int monthlycount;

  const AiUserLimitModel({
    required this.userid,
    required this.dailylimit,
    required this.monthlylimit,
    required this.dailycount,
    required this.monthlycount,
  });

  factory AiUserLimitModel.fromJson(Map<String, dynamic> json) {
    return AiUserLimitModel(
      userid: json['userid'] as int? ?? 0,
      dailylimit: json['dailylimit'] as int? ?? 50,
      monthlylimit: json['monthlylimit'] as int? ?? 1000,
      dailycount: json['dailycount'] as int? ?? 0,
      monthlycount: json['monthlycount'] as int? ?? 0,
    );
  }

  double get dailyUsagePercent =>
      dailylimit > 0 ? (dailycount / dailylimit).clamp(0.0, 1.0) : 0.0;
  double get monthlyUsagePercent =>
      monthlylimit > 0 ? (monthlycount / monthlylimit).clamp(0.0, 1.0) : 0.0;
}
