import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../network/network_info.dart';
import '../storage/offline_queue.dart';

/// Connectivity state.
enum ConnectivityStatus { online, offline }

/// Global connectivity cubit that listens to network changes
/// and triggers sync when connection is restored.
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  final NetworkInfo _networkInfo;
  final OfflineQueue _offlineQueue;
  StreamSubscription<bool>? _subscription;

  ConnectivityCubit({
    required NetworkInfo networkInfo,
    required OfflineQueue offlineQueue,
  }) : _networkInfo = networkInfo,
       _offlineQueue = offlineQueue,
       super(ConnectivityStatus.online) {
    _init();
  }

  Future<void> _init() async {
    // Check initial state
    final connected = await _networkInfo.isConnected;
    emit(connected ? ConnectivityStatus.online : ConnectivityStatus.offline);

    // Listen to changes
    _subscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      final newStatus = isConnected
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;
      final wasOffline = state == ConnectivityStatus.offline;

      emit(newStatus);

      // Auto-sync when coming back online
      if (isConnected && wasOffline) {
        dev.log('[ConnectivityCubit] Back online — syncing queued actions');
        _offlineQueue.processAll();
      }
    });
  }

  bool get isOnline => state == ConnectivityStatus.online;
  bool get isOffline => state == ConnectivityStatus.offline;

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
