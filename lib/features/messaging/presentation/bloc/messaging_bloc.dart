import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/message.dart';
import '../../domain/repositories/messaging_repository.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository repository;

  MessagingBloc({required this.repository}) : super(MessagingInitial()) {
    on<LoadConversations>(_onLoadConversations);
    on<LoadMessages>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<DeleteMessageEvent>(_onDeleteMessage);
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    final result = await repository.getConversations(event.userId);
    result.fold(
      (f) => emit(MessagingError(message: f.message)),
      (conversations) =>
          emit(ConversationsLoaded(conversations: conversations)),
    );
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    // Only show loading spinner if we don't already have messages
    if (state is! MessagesLoaded && state is! MessageSent) {
      emit(MessagingLoading());
    }
    final result = await repository.getConversationMessages(
      event.conversationId,
      event.userId,
    );
    result.fold(
      (f) => emit(MessagingError(message: f.message)),
      (messages) => emit(MessagesLoaded(messages: messages)),
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final result = await repository.sendMessage(event.toUserId, event.message);
    result.fold(
      (f) => emit(MessagingError(message: f.message)),
      (_) => emit(MessageSent()),
    );
  }

  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final result = await repository.deleteMessage(
      event.messageId,
      event.userId,
    );
    result.fold(
      (f) => emit(MessagingError(message: f.message)),
      (_) => emit(MessageDeleted()),
    );
  }
}
