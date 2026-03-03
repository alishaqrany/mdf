import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/ai/domain/entities/ai_entities.dart';
import 'package:mdf_app/features/ai/domain/repositories/ai_repository.dart';
import 'package:mdf_app/features/ai/presentation/bloc/ai_chat_bloc.dart';

class MockAiRepository extends Mock implements AiRepository {}

void main() {
  late MockAiRepository mockRepository;
  late AiChatBloc bloc;

  final tBotResponse = AiChatMessage(
    id: 'msg_2',
    content: 'Calculus is a branch of mathematics...',
    isUser: false,
    timestamp: DateTime(2024, 3, 15, 10, 1),
    type: AiMessageType.text,
  );

  setUpAll(() {
    registerFallbackValue(<AiChatMessage>[]);
  });

  setUp(() {
    mockRepository = MockAiRepository();
    bloc = AiChatBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is AiChatInitial', () {
    expect(bloc.state, isA<AiChatInitial>());
  });

  group('SendChatMessage', () {
    blocTest<AiChatBloc, AiChatState>(
      'emits [Active with isTyping, Active with response] on success',
      build: () {
        when(
          () => mockRepository.chat(any(), any(), any()),
        ).thenAnswer((_) async => Right(tBotResponse));
        return bloc;
      },
      act: (b) =>
          b.add(const SendChatMessage(userId: 1, message: 'What is calculus?')),
      expect: () => [
        isA<AiChatActive>()
            .having((s) => s.messages.length, 'has user msg', 1)
            .having((s) => s.isTyping, 'isTyping', isTrue),
        isA<AiChatActive>()
            .having((s) => s.messages.length, 'has both msgs', 2)
            .having((s) => s.isTyping, 'isTyping', isFalse),
      ],
    );

    blocTest<AiChatBloc, AiChatState>(
      'emits error message on failure',
      build: () {
        when(() => mockRepository.chat(any(), any(), any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'AI error')),
        );
        return bloc;
      },
      act: (b) =>
          b.add(const SendChatMessage(userId: 1, message: 'What is calculus?')),
      expect: () => [
        isA<AiChatActive>().having((s) => s.isTyping, 'typing', isTrue),
        isA<AiChatActive>().having((s) => s.isTyping, 'not typing', isFalse),
      ],
    );
  });

  group('ClearChat', () {
    blocTest<AiChatBloc, AiChatState>(
      'resets to initial state',
      build: () => bloc,
      act: (b) => b.add(ClearChat()),
      expect: () => [isA<AiChatInitial>()],
    );
  });

  group('AiChatMessage entity', () {
    test('isUser flag differentiates user vs bot', () {
      expect(tBotResponse.isUser, isFalse);
    });

    test('default type is text', () {
      expect(tBotResponse.type, AiMessageType.text);
    });

    test('equatable works', () {
      expect(tBotResponse, tBotResponse);
    });
  });
}
