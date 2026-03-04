/// Model for a chat message stored on the server.
class AiMessageModel {
  final int? id;
  final int userid;
  final String role;
  final String content;
  final String provider;
  final int tokensused;
  final int timecreated;

  const AiMessageModel({
    this.id,
    required this.userid,
    required this.role,
    required this.content,
    this.provider = 'local',
    this.tokensused = 0,
    required this.timecreated,
  });

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id'] as int?,
      userid: json['userid'] as int? ?? 0,
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      provider: json['provider'] as String? ?? 'local',
      tokensused: json['tokensused'] as int? ?? 0,
      timecreated: json['timecreated'] as int? ?? 0,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timecreated * 1000);
}
