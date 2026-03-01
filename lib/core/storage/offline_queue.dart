import 'dart:convert';
import 'dart:developer' as dev;

import 'package:hive_flutter/hive_flutter.dart';

import 'cache_config.dart';

/// Represents a queued offline action to be synced when online.
class OfflineAction {
  final String id;
  final String type; // e.g. 'send_message', 'submit_assignment', 'mark_read'
  final Map<String, dynamic> payload;
  final int createdAt;
  int retryCount;
  String? lastError;

  OfflineAction({
    required this.id,
    required this.type,
    required this.payload,
    int? createdAt,
    this.retryCount = 0,
    this.lastError,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'payload': jsonEncode(payload),
    'createdAt': createdAt,
    'retryCount': retryCount,
    'lastError': lastError,
  };

  factory OfflineAction.fromMap(Map<dynamic, dynamic> map) {
    return OfflineAction(
      id: map['id'] as String? ?? '',
      type: map['type'] as String? ?? '',
      payload: map['payload'] != null
          ? Map<String, dynamic>.from(
              jsonDecode(map['payload'] as String) as Map,
            )
          : {},
      createdAt: map['createdAt'] as int? ?? 0,
      retryCount: map['retryCount'] as int? ?? 0,
      lastError: map['lastError'] as String?,
    );
  }
}

/// Callback type for processing queued actions.
typedef ActionProcessor = Future<bool> Function(OfflineAction action);

/// Manages a queue of offline actions with retry logic.
class OfflineQueue {
  static const int maxRetries = 3;

  late Box _box;
  final Map<String, ActionProcessor> _processors = {};

  /// Initialize the queue.
  Future<void> init() async {
    _box = Hive.box(CacheConfig.offlineQueueBox);
  }

  /// Register a processor for a specific action type.
  void registerProcessor(String type, ActionProcessor processor) {
    _processors[type] = processor;
  }

  /// Add an action to the queue.
  Future<void> enqueue(OfflineAction action) async {
    await _box.put(action.id, action.toMap());
    dev.log('[OfflineQueue] Enqueued: ${action.type} (${action.id})');
  }

  /// Get all pending actions.
  List<OfflineAction> getPending() {
    final result = <OfflineAction>[];
    for (final key in _box.keys) {
      final raw = _box.get(key);
      if (raw is Map) {
        result.add(OfflineAction.fromMap(raw));
      }
    }
    result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return result;
  }

  /// Number of pending actions.
  int get pendingCount => _box.length;

  /// Process all pending actions (call when back online).
  /// Returns the number of successfully processed actions.
  Future<int> processAll() async {
    int processed = 0;
    final pending = getPending();

    for (final action in pending) {
      final processor = _processors[action.type];
      if (processor == null) {
        dev.log('[OfflineQueue] No processor for type: ${action.type}');
        continue;
      }

      try {
        final success = await processor(action);
        if (success) {
          await _box.delete(action.id);
          processed++;
          dev.log('[OfflineQueue] Processed: ${action.type} (${action.id})');
        } else {
          action.retryCount++;
          if (action.retryCount >= maxRetries) {
            await _box.delete(action.id);
            dev.log(
              '[OfflineQueue] Max retries reached, removing: ${action.id}',
            );
          } else {
            await _box.put(action.id, action.toMap());
          }
        }
      } catch (e) {
        action.retryCount++;
        action.lastError = e.toString();
        if (action.retryCount >= maxRetries) {
          await _box.delete(action.id);
        } else {
          await _box.put(action.id, action.toMap());
        }
        dev.log('[OfflineQueue] Error processing ${action.id}: $e');
      }
    }

    if (processed > 0) {
      dev.log(
        '[OfflineQueue] Processed $processed / ${pending.length} actions',
      );
    }
    return processed;
  }

  /// Clear all pending actions.
  Future<void> clearAll() async {
    await _box.clear();
  }
}
