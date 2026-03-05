import 'dart:developer' as dev;
import '../../../../core/api/moodle_api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/message_model.dart';

abstract class MessagingRemoteDataSource {
  Future<List<ConversationModel>> getConversations(int userId);
  Future<List<MessageModel>> getConversationMessages(
    int conversationId,
    int userId,
  );
  Future<void> sendMessage(int userId, String message);
  Future<void> deleteMessage(int messageId, int userId);
  Future<int> uploadFile(String filePath, String fileName);
}

class MessagingRemoteDataSourceImpl implements MessagingRemoteDataSource {
  final MoodleApiClient apiClient;

  MessagingRemoteDataSourceImpl({required this.apiClient});

  Future<int> _resolveUserId(int userId) async {
    if (userId != 0) return userId;
    final siteInfo = await apiClient.call(MoodleApiEndpoints.getSiteInfo);
    return (siteInfo as Map<String, dynamic>)['userid'] as int? ?? 0;
  }

  @override
  Future<List<ConversationModel>> getConversations(int userId) async {
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == 0) return [];

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getConversations,
        params: {'userid': resolvedUserId},
      );

      dev.log('getConversations response type: ${response.runtimeType}');

      List<dynamic>? convList;

      if (response is Map && response.containsKey('conversations')) {
        convList = response['conversations'] as List?;
      } else if (response is List) {
        // Some Moodle versions return a plain list
        convList = response;
      } else if (response is Map) {
        // Moodle may return error or empty object
        dev.log('getConversations unexpected map keys: ${response.keys}');
        // Check if the map itself looks like an error
        if (response.containsKey('exception')) {
          dev.log('Moodle error: ${response['message']}');
          return [];
        }
      }

      if (convList != null) {
        return convList
            .map((j) => ConversationModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      dev.log('getConversations error: $e\n$st');
    }
    return [];
  }

  @override
  Future<List<MessageModel>> getConversationMessages(
    int conversationId,
    int userId,
  ) async {
    final resolvedUserId = await _resolveUserId(userId);
    if (resolvedUserId == 0) return [];

    try {
      final response = await apiClient.call(
        MoodleApiEndpoints.getConversationMessages,
        params: {'currentuserid': resolvedUserId, 'convid': conversationId},
      );

      dev.log('getConversationMessages response type: ${response.runtimeType}');

      List<dynamic>? msgList;

      if (response is Map && response.containsKey('messages')) {
        msgList = response['messages'] as List?;
      } else if (response is List) {
        msgList = response;
      }

      if (msgList != null) {
        return msgList
            .map((j) => MessageModel.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (e, st) {
      dev.log('getConversationMessages error: $e\n$st');
    }
    return [];
  }

  @override
  Future<void> sendMessage(int userId, String message) async {
    await apiClient.call(
      MoodleApiEndpoints.sendInstantMessages,
      params: {'messages[0][touserid]': userId, 'messages[0][text]': message},
    );
  }

  @override
  Future<void> deleteMessage(int messageId, int userId) async {
    final resolvedUserId = await _resolveUserId(userId);
    await apiClient.call(
      'core_message_delete_message',
      params: {'messageid': messageId, 'userid': resolvedUserId},
    );
  }

  @override
  Future<int> uploadFile(String filePath, String fileName) async {
    final response = await apiClient.uploadFile(
      filePath: filePath,
      fileName: fileName,
      fileArea: 'draft',
      itemId: 0,
    );
    if (response.isNotEmpty && response[0] is Map) {
      return (response[0] as Map)['itemid'] as int? ?? 0;
    }
    return 0;
  }
}
