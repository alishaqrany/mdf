import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/network/connectivity_cubit.dart';
import 'package:mdf_app/core/network/network_info.dart';
import 'package:mdf_app/core/storage/offline_queue.dart';

// ─── Mocks ───
class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockOfflineQueue extends Mock implements OfflineQueue {}

void main() {
  late MockNetworkInfo mockNetworkInfo;
  late MockOfflineQueue mockOfflineQueue;
  late StreamController<bool> connectivityController;

  setUp(() {
    mockNetworkInfo = MockNetworkInfo();
    mockOfflineQueue = MockOfflineQueue();
    connectivityController = StreamController<bool>.broadcast();

    when(
      () => mockNetworkInfo.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => mockOfflineQueue.processAll()).thenAnswer((_) async => 0);
  });

  tearDown(() {
    connectivityController.close();
  });

  group('ConnectivityCubit', () {
    blocTest<ConnectivityCubit, ConnectivityStatus>(
      'starts online when network is connected',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        return ConnectivityCubit(
          networkInfo: mockNetworkInfo,
          offlineQueue: mockOfflineQueue,
        );
      },
      // Give time for async _init
      wait: const Duration(milliseconds: 50),
      expect: () => [ConnectivityStatus.online],
    );

    blocTest<ConnectivityCubit, ConnectivityStatus>(
      'starts offline when network is not connected',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return ConnectivityCubit(
          networkInfo: mockNetworkInfo,
          offlineQueue: mockOfflineQueue,
        );
      },
      wait: const Duration(milliseconds: 50),
      expect: () => [ConnectivityStatus.offline],
    );

    blocTest<ConnectivityCubit, ConnectivityStatus>(
      'emits offline then online when connectivity changes',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        return ConnectivityCubit(
          networkInfo: mockNetworkInfo,
          offlineQueue: mockOfflineQueue,
        );
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 50));
        connectivityController.add(false);
        await Future.delayed(const Duration(milliseconds: 50));
        connectivityController.add(true);
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        ConnectivityStatus.online,
        ConnectivityStatus.offline,
        ConnectivityStatus.online,
      ],
    );

    blocTest<ConnectivityCubit, ConnectivityStatus>(
      'processes offline queue when coming back online',
      build: () {
        when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return ConnectivityCubit(
          networkInfo: mockNetworkInfo,
          offlineQueue: mockOfflineQueue,
        );
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 50));
        connectivityController.add(true);
        await Future.delayed(const Duration(milliseconds: 50));
      },
      wait: const Duration(milliseconds: 200),
      verify: (_) {
        verify(() => mockOfflineQueue.processAll()).called(1);
      },
    );

    test('isOnline / isOffline getters', () async {
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      final cubit = ConnectivityCubit(
        networkInfo: mockNetworkInfo,
        offlineQueue: mockOfflineQueue,
      );
      // Wait for async _init
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.isOnline, true);
      expect(cubit.isOffline, false);
      await cubit.close();
    });
  });
}
