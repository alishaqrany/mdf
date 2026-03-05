import 'dart:convert';

import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/moodle_api_client.dart';
import '../models/ai_config_model.dart';
import '../models/ai_message_model.dart';
import '../models/ai_usage_model.dart';

/// Remote data source for admin AI operations (config, usage, limits, proxy).
abstract class AiRemoteDataSource {
  /// Send a message to the AI via server-side proxy and get a response.
  Future<AiProxyResponse> proxyAiRequest({
    required String message,
    List<Map<String, String>> history,
    String? provider,
    String locale,
  });

  /// Save a chat message to the server for history tracking.
  Future<void> saveChatMessage({
    required int userid,
    required String role,
    required String content,
    String provider,
    int tokensused,
  });

  /// Get chat history from the server.
  Future<List<AiMessageModel>> getChatHistory({
    int? userid,
    int limit,
    int? before,
  });

  /// Get all AI provider configurations (admin only).
  Future<List<AiConfigModel>> getAiConfigs();

  /// Save/update an AI provider configuration.
  Future<void> saveAiConfig(AiConfigModel config);

  /// Get AI usage statistics.
  Future<AiUsageStatsModel> getAiUsageStats({int days});

  /// Get AI usage limits for a user.
  Future<AiUserLimitModel> getAiUserLimit({int userid});

  /// Set AI usage limits for a user.
  Future<void> setAiUserLimit({int userid, int dailylimit, int monthlylimit});
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final MoodleApiClient apiClient;

  AiRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<AiProxyResponse> proxyAiRequest({
    required String message,
    List<Map<String, String>>? history,
    String? provider,
    String locale = 'en',
  }) async {
    // Build a JSON array of {role, content} messages as the PHP endpoint expects.
    final messageArray = <Map<String, String>>[];
    if (history != null) {
      messageArray.addAll(history);
    }
    messageArray.add({'role': 'user', 'content': message});

    final params = <String, dynamic>{
      'messages': jsonEncode(messageArray),
    };
    if (provider != null && provider.isNotEmpty) {
      params['provider'] = provider;
    }

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfProxyAiRequest,
      params: params,
    );

    if (response is Map<String, dynamic>) {
      return AiProxyResponse.fromJson(response);
    }
    throw Exception('Invalid AI proxy response');
  }

  @override
  Future<void> saveChatMessage({
    required int userid,
    required String role,
    required String content,
    String provider = 'local',
    int tokensused = 0,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfSaveChatMessage,
      params: {
        'userid': userid,
        'role': role,
        'content': content,
        'provider': provider,
        'tokensused': tokensused,
      },
    );
  }

  @override
  Future<List<AiMessageModel>> getChatHistory({
    int? userid,
    int limit = 50,
    int? before,
  }) async {
    final params = <String, dynamic>{'limit': limit};
    if (userid != null) params['userid'] = userid;
    if (before != null) params['before'] = before;

    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetChatHistory,
      params: params,
    );

    if (response is Map<String, dynamic> && response.containsKey('messages')) {
      return (response['messages'] as List)
          .map((e) => AiMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<List<AiConfigModel>> getAiConfigs() async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetAiConfig,
      params: {},
    );

    if (response is Map<String, dynamic> && response.containsKey('configs')) {
      return (response['configs'] as List)
          .map((e) => AiConfigModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  Future<void> saveAiConfig(AiConfigModel config) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfSaveAiConfig,
      params: {
        'provider': config.provider,
        'apikey': config.apikey,
        'model': config.model,
        'systemprompt': config.systemprompt,
        'maxtokens': config.maxtokens,
        'temperature': config.temperature,
        'enabled': config.enabled ? 1 : 0,
      },
    );
  }

  @override
  Future<AiUsageStatsModel> getAiUsageStats({int days = 30}) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetAiUsageStats,
      params: {'days': days},
    );

    if (response is Map<String, dynamic>) {
      return AiUsageStatsModel.fromJson(response);
    }
    throw Exception('Invalid usage stats response');
  }

  @override
  Future<AiUserLimitModel> getAiUserLimit({int userid = 0}) async {
    final response = await apiClient.call(
      MoodleApiEndpoints.mdfGetAiUserLimit,
      params: {'userid': userid},
    );

    if (response is Map<String, dynamic>) {
      return AiUserLimitModel.fromJson(response);
    }
    throw Exception('Invalid user limit response');
  }

  @override
  Future<void> setAiUserLimit({
    int userid = 0,
    int dailylimit = 50,
    int monthlylimit = 1000,
  }) async {
    await apiClient.call(
      MoodleApiEndpoints.mdfSetAiUserLimit,
      params: {
        'userid': userid,
        'dailylimit': dailylimit,
        'monthlylimit': monthlylimit,
      },
    );
  }
}

/// Response from the AI proxy endpoint.
class AiProxyResponse {
  final bool success;
  final String content;
  final String provider;
  final String model;
  final int tokensused;
  final String? error;

  AiProxyResponse({
    required this.success,
    required this.content,
    required this.provider,
    required this.model,
    required this.tokensused,
    this.error,
  });

  factory AiProxyResponse.fromJson(Map<String, dynamic> json) {
    return AiProxyResponse(
      success: json['success'] == true || json['success'] == 1,
      content: json['content'] as String? ?? '',
      provider: json['provider'] as String? ?? 'unknown',
      model: json['model'] as String? ?? '',
      tokensused: json['tokensused'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }
}
