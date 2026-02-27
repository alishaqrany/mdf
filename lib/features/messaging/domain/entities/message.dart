import 'package:equatable/equatable.dart';

/// A messaging conversation.
class Conversation extends Equatable {
  final int id;
  final String? name;
  final int? type; // 1=individual, 2=group, 3=self
  final int memberCount;
  final bool isMuted;
  final bool isFavourite;
  final bool isRead;
  final int unreadCount;
  final List<ConversationMember> members;
  final List<Message> messages;

  const Conversation({
    required this.id,
    this.name,
    this.type,
    this.memberCount = 0,
    this.isMuted = false,
    this.isFavourite = false,
    this.isRead = true,
    this.unreadCount = 0,
    this.members = const [],
    this.messages = const [],
  });

  @override
  List<Object?> get props => [id];
}

/// A member of a conversation.
class ConversationMember extends Equatable {
  final int id;
  final String fullName;
  final String? profileImageUrl;
  final bool? isOnline;

  const ConversationMember({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.isOnline,
  });

  @override
  List<Object?> get props => [id, fullName];
}

/// A chat message.
class Message extends Equatable {
  final int id;
  final int userIdFrom;
  final String? text;
  final int? timeCreated;
  final bool? isRead;

  const Message({
    required this.id,
    required this.userIdFrom,
    this.text,
    this.timeCreated,
    this.isRead,
  });

  @override
  List<Object?> get props => [id, userIdFrom];
}
