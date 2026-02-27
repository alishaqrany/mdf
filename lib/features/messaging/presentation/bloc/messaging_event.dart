part of 'messaging_bloc.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversations extends MessagingEvent {
  final int userId;
  const LoadConversations({required this.userId});
  @override
  List<Object?> get props => [userId];
}

class LoadMessages extends MessagingEvent {
  final int conversationId;
  final int userId;
  const LoadMessages({required this.conversationId, required this.userId});
  @override
  List<Object?> get props => [conversationId, userId];
}

class SendMessageEvent extends MessagingEvent {
  final int toUserId;
  final String message;
  const SendMessageEvent({required this.toUserId, required this.message});
  @override
  List<Object?> get props => [toUserId, message];
}
