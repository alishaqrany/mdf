import '../../domain/entities/message.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    super.name,
    super.type,
    super.memberCount,
    super.isMuted,
    super.isFavourite,
    super.isRead,
    super.unreadCount,
    super.members,
    super.messages,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'] as List? ?? [];
    final messagesJson = json['messages'] as List? ?? [];

    return ConversationModel(
      id: json['id'] as int,
      name: json['name'] as String?,
      type: json['type'] as int?,
      memberCount: json['membercount'] as int? ?? 0,
      isMuted: json['ismuted'] as bool? ?? false,
      isFavourite: json['isfavourite'] as bool? ?? false,
      isRead: json['isread'] as bool? ?? true,
      unreadCount: json['unreadcount'] as int? ?? 0,
      members: membersJson
          .map<ConversationMember>(
            (m) => ConversationMemberModel.fromJson(m as Map<String, dynamic>),
          )
          .toList(),
      messages: messagesJson
          .map<Message>((m) => MessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ConversationMemberModel extends ConversationMember {
  const ConversationMemberModel({
    required super.id,
    required super.fullName,
    super.profileImageUrl,
    super.isOnline,
  });

  factory ConversationMemberModel.fromJson(Map<String, dynamic> json) {
    return ConversationMemberModel(
      id: json['id'] as int,
      fullName: json['fullname'] as String? ?? '',
      profileImageUrl: json['profileimageurl'] as String?,
      isOnline: json['isonline'] as bool?,
    );
  }
}

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.userIdFrom,
    super.text,
    super.timeCreated,
    super.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as int,
      userIdFrom: json['useridfrom'] as int? ?? 0,
      text: json['text'] as String?,
      timeCreated: json['timecreated'] as int?,
      isRead: json['isread'] as bool?,
    );
  }
}
