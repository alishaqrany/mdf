import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/messaging/domain/entities/message.dart';
import 'package:mdf_app/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:mdf_app/features/messaging/presentation/bloc/messaging_bloc.dart';

class MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late MockMessagingRepository mockRepository;
  late MessagingBloc bloc;

  const tConversation = Conversation(
    id: 1,
    name: 'Test Chat',
    type: 1,
    memberCount: 2,
    isRead: false,
    unreadCount: 3,
  );

  const tMessage = Message(
    id: 1,
    userIdFrom: 10,
    text: 'Hello!',
    timeCreated: 1700000000,
    isRead: true,
  );

  setUp(() {
    mockRepository = MockMessagingRepository();
    bloc = MessagingBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is MessagingInitial', () {
    expect(bloc.state, isA<MessagingInitial>());
  });

  group('LoadConversations', () {
    blocTest<MessagingBloc, MessagingState>(
      'emits [Loading, ConversationsLoaded] on success',
      build: () {
        when(
          () => mockRepository.getConversations(1),
        ).thenAnswer((_) async => const Right([tConversation]));
        return bloc;
      },
      act: (b) => b.add(const LoadConversations(userId: 1)),
      expect: () => [
        isA<MessagingLoading>(),
        isA<ConversationsLoaded>().having(
          (s) => s.conversations.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<MessagingBloc, MessagingState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getConversations(1)).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Server error')),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadConversations(userId: 1)),
      expect: () => [
        isA<MessagingLoading>(),
        isA<MessagingError>().having(
          (s) => s.message,
          'message',
          'Server error',
        ),
      ],
    );
  });

  group('LoadMessages', () {
    blocTest<MessagingBloc, MessagingState>(
      'emits [Loading, MessagesLoaded] on success',
      build: () {
        when(
          () => mockRepository.getConversationMessages(1, 10),
        ).thenAnswer((_) async => const Right([tMessage]));
        return bloc;
      },
      act: (b) => b.add(const LoadMessages(conversationId: 1, userId: 10)),
      expect: () => [
        isA<MessagingLoading>(),
        isA<MessagesLoaded>().having(
          (s) => s.messages.first.text,
          'text',
          'Hello!',
        ),
      ],
    );

    blocTest<MessagingBloc, MessagingState>(
      'emits [Loading, Error] on network failure',
      build: () {
        when(
          () => mockRepository.getConversationMessages(1, 10),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return bloc;
      },
      act: (b) => b.add(const LoadMessages(conversationId: 1, userId: 10)),
      expect: () => [
        isA<MessagingLoading>(),
        isA<MessagingError>().having(
          (s) => s.message,
          'message',
          'No internet connection',
        ),
      ],
    );
  });

  group('SendMessageEvent', () {
    blocTest<MessagingBloc, MessagingState>(
      'emits [MessageSent] on success (no Loading)',
      build: () {
        when(
          () => mockRepository.sendMessage(10, 'Hi there'),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (b) =>
          b.add(const SendMessageEvent(toUserId: 10, message: 'Hi there')),
      expect: () => [isA<MessageSent>()],
    );

    blocTest<MessagingBloc, MessagingState>(
      'emits [Error] on failure',
      build: () {
        when(() => mockRepository.sendMessage(any(), any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Failed to send')),
        );
        return bloc;
      },
      act: (b) => b.add(const SendMessageEvent(toUserId: 10, message: 'Hi')),
      expect: () => [isA<MessagingError>()],
    );
  });
}
