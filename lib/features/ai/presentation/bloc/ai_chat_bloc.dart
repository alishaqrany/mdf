import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ai_entities.dart';
import '../../domain/repositories/ai_repository.dart';

// ─── Events ───
abstract class AiChatEvent extends Equatable {
  const AiChatEvent();
  @override
  List<Object?> get props => [];
}

class SendChatMessage extends AiChatEvent {
  final int userId;
  final String message;
  const SendChatMessage({required this.userId, required this.message});
  @override
  List<Object?> get props => [userId, message];
}

class ClearChat extends AiChatEvent {}

// ─── States ───
abstract class AiChatState extends Equatable {
  const AiChatState();
  @override
  List<Object?> get props => [];
}

class AiChatInitial extends AiChatState {}

class AiChatActive extends AiChatState {
  final List<AiChatMessage> messages;
  final bool isTyping;

  const AiChatActive({required this.messages, this.isTyping = false});

  @override
  List<Object?> get props => [messages, isTyping];
}

// ─── Bloc ───
class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  final AiRepository repository;

  AiChatBloc({required this.repository}) : super(AiChatInitial()) {
    on<SendChatMessage>(_onSend);
    on<ClearChat>(_onClear);
  }

  final List<AiChatMessage> _history = [];

  Future<void> _onSend(SendChatMessage event, Emitter<AiChatState> emit) async {
    // Add user message
    final userMsg = AiChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: event.message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _history.add(userMsg);
    emit(AiChatActive(messages: List.of(_history), isTyping: true));

    // Pass history WITHOUT the latest user message — proxyAiRequest() will
    // append it, so including it here would duplicate the user turn.
    final historyForApi = _history.sublist(0, _history.length - 1);
    final result = await repository.chat(
      event.userId,
      event.message,
      historyForApi,
    );

    result.fold(
      (failure) {
        final errorMsg = AiChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          content: failure.message.isNotEmpty
              ? failure.message
              : 'Sorry, I encountered an error. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
          type: AiMessageType.error,
        );
        _history.add(errorMsg);
        emit(AiChatActive(messages: List.of(_history)));
      },
      (response) {
        _history.add(response);
        emit(AiChatActive(messages: List.of(_history)));
      },
    );
  }

  void _onClear(ClearChat event, Emitter<AiChatState> emit) {
    _history.clear();
    emit(AiChatInitial());
  }
}
