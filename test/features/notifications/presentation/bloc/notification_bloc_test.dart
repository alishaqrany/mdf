import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/notifications/domain/entities/notification.dart';
import 'package:mdf_app/features/notifications/domain/repositories/notification_repository.dart';
import 'package:mdf_app/features/notifications/presentation/bloc/notification_bloc.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MockNotificationRepository mockRepository;
  late NotificationBloc bloc;

  const tNotification = AppNotification(
    id: 1,
    userIdFrom: 5,
    userIdTo: 1,
    subject: 'New assignment',
    fullMessage: 'You have a new assignment due.',
    component: 'mod_assign',
    eventType: 'assign_notification',
    timeCreated: 1700000000,
    isRead: false,
  );

  setUp(() {
    mockRepository = MockNotificationRepository();
    bloc = NotificationBloc(repository: mockRepository);
  });

  tearDown(() => bloc.close());

  test('initial state is NotificationInitial', () {
    expect(bloc.state, isA<NotificationInitial>());
  });

  group('LoadNotifications', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(
          () => mockRepository.getNotifications(1),
        ).thenAnswer((_) async => const Right([tNotification]));
        return bloc;
      },
      act: (b) => b.add(const LoadNotifications(userId: 1)),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationsLoaded>().having(
          (s) => s.notifications.length,
          'count',
          1,
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(() => mockRepository.getNotifications(1)).thenAnswer(
          (_) async => const Left(
            ServerFailure(message: 'Failed to load notifications'),
          ),
        );
        return bloc;
      },
      act: (b) => b.add(const LoadNotifications(userId: 1)),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationError>().having(
          (s) => s.message,
          'message',
          'Failed to load notifications',
        ),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'loads empty list on success with no notifications',
      build: () {
        when(
          () => mockRepository.getNotifications(1),
        ).thenAnswer((_) async => const Right([]));
        return bloc;
      },
      act: (b) => b.add(const LoadNotifications(userId: 1)),
      expect: () => [
        isA<NotificationLoading>(),
        isA<NotificationsLoaded>().having(
          (s) => s.notifications,
          'notifications',
          isEmpty,
        ),
      ],
    );
  });

  group('MarkNotificationRead', () {
    blocTest<NotificationBloc, NotificationState>(
      'calls markRead then re-loads notifications',
      build: () {
        when(
          () => mockRepository.markRead(1),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepository.getNotifications(1),
        ).thenAnswer((_) async => const Right([tNotification]));
        return bloc;
      },
      act: (b) =>
          b.add(const MarkNotificationRead(notificationId: 1, userId: 1)),
      expect: () => [
        // Re-added LoadNotifications triggers Loading then Loaded
        isA<NotificationLoading>(),
        isA<NotificationsLoaded>(),
      ],
      verify: (_) {
        verify(() => mockRepository.markRead(1)).called(1);
      },
    );
  });

  // ─── NotificationBadgeCubit ───
  group('NotificationBadgeCubit', () {
    late NotificationBadgeCubit cubit;

    setUp(() {
      cubit = NotificationBadgeCubit(repository: mockRepository);
    });

    tearDown(() => cubit.close());

    test('initial state is 0', () {
      expect(cubit.state, 0);
    });

    blocTest<NotificationBadgeCubit, int>(
      'emits unread count on loadUnreadCount success',
      build: () {
        when(
          () => mockRepository.getUnreadCount(1),
        ).thenAnswer((_) async => const Right(5));
        return cubit;
      },
      act: (c) => c.loadUnreadCount(1),
      expect: () => [5],
    );

    blocTest<NotificationBadgeCubit, int>(
      'emits 0 on loadUnreadCount failure',
      build: () {
        when(
          () => mockRepository.getUnreadCount(1),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'Error')));
        return cubit;
      },
      act: (c) => c.loadUnreadCount(1),
      expect: () => [0],
    );

    blocTest<NotificationBadgeCubit, int>(
      'decrement reduces count by 1',
      seed: () => 5,
      build: () => cubit,
      act: (c) => c.decrement(),
      expect: () => [4],
    );

    blocTest<NotificationBadgeCubit, int>(
      'decrement does not emit when already 0',
      seed: () => 0,
      build: () => cubit,
      act: (c) => c.decrement(),
      expect: () => [],
    );

    blocTest<NotificationBadgeCubit, int>(
      'clear resets to 0',
      seed: () => 10,
      build: () => cubit,
      act: (c) => c.clear(),
      expect: () => [0],
    );
  });
}
