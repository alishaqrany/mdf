import 'dart:convert';
import 'dart:developer' as dev;

import 'package:hive_flutter/hive_flutter.dart';

import 'cache_config.dart';

/// A cached entry wrapping data with a timestamp for TTL checks.
class CacheEntry {
  final String data;
  final int timestampMs;

  CacheEntry({required this.data, required this.timestampMs});

  Map<String, dynamic> toMap() => {'data': data, 'ts': timestampMs};

  factory CacheEntry.fromMap(Map<dynamic, dynamic> map) {
    return CacheEntry(
      data: map['data'] as String? ?? '',
      timestampMs: map['ts'] as int? ?? 0,
    );
  }

  bool isExpired(Duration ttl) {
    return DateTime.now().millisecondsSinceEpoch - timestampMs >
        ttl.inMilliseconds;
  }
}

/// Hive-based caching manager.
///
/// Provides get/put/delete/clear operations with automatic TTL expiry.
class CacheManager {
  CacheManager._();

  /// Initialize Hive and open all cache boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    // Open all cache boxes
    await Future.wait([
      Hive.openBox(CacheConfig.coursesBox),
      Hive.openBox(CacheConfig.courseContentBox),
      Hive.openBox(CacheConfig.gradesBox),
      Hive.openBox(CacheConfig.calendarBox),
      Hive.openBox(CacheConfig.notificationsBox),
      Hive.openBox(CacheConfig.profileBox),
      Hive.openBox(CacheConfig.forumsBox),
      Hive.openBox(CacheConfig.downloadsBox),
      Hive.openBox(CacheConfig.offlineQueueBox),
    ]);
    dev.log('[CacheManager] All Hive boxes initialized');
  }

  // ─── Read ───

  /// Get cached data for [key] from [boxName].
  /// Returns `null` if not found or expired.
  static T? get<T>({
    required String boxName,
    required String key,
    Duration ttl = CacheConfig.defaultTTL,
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(key);
      if (raw == null) return null;

      final entry = CacheEntry.fromMap(raw as Map<dynamic, dynamic>);
      if (entry.isExpired(ttl)) {
        box.delete(key); // Auto-clean expired
        return null;
      }

      final decoded = jsonDecode(entry.data);
      if (fromJson != null && decoded is Map<String, dynamic>) {
        return fromJson(decoded);
      }
      return decoded as T?;
    } catch (e) {
      dev.log('[CacheManager] get error ($boxName/$key): $e');
      return null;
    }
  }

  /// Get cached list data for [key] from [boxName].
  static List<T>? getList<T>({
    required String boxName,
    required String key,
    Duration ttl = CacheConfig.defaultTTL,
    T Function(Map<String, dynamic>)? fromJson,
  }) {
    try {
      final box = Hive.box(boxName);
      final raw = box.get(key);
      if (raw == null) return null;

      final entry = CacheEntry.fromMap(raw as Map<dynamic, dynamic>);
      if (entry.isExpired(ttl)) {
        box.delete(key);
        return null;
      }

      final decoded = jsonDecode(entry.data) as List;
      if (fromJson != null) {
        return decoded
            .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return decoded.cast<T>();
    } catch (e) {
      dev.log('[CacheManager] getList error ($boxName/$key): $e');
      return null;
    }
  }

  // ─── Write ───

  /// Put data into cache with current timestamp.
  static Future<void> put({
    required String boxName,
    required String key,
    required dynamic data,
  }) async {
    try {
      final box = Hive.box(boxName);

      // Enforce max entries
      if (CacheConfig.maxEntriesPerBox > 0 &&
          box.length >= CacheConfig.maxEntriesPerBox) {
        // Remove oldest entry
        await box.deleteAt(0);
      }

      final jsonStr = jsonEncode(data);
      final entry = CacheEntry(
        data: jsonStr,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      );
      await box.put(key, entry.toMap());
    } catch (e) {
      dev.log('[CacheManager] put error ($boxName/$key): $e');
    }
  }

  // ─── Delete ───

  /// Delete a specific key from a box.
  static Future<void> delete({
    required String boxName,
    required String key,
  }) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
    } catch (e) {
      dev.log('[CacheManager] delete error ($boxName/$key): $e');
    }
  }

  /// Clear all entries in a specific box.
  static Future<void> clearBox(String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
      dev.log('[CacheManager] cleared box: $boxName');
    } catch (e) {
      dev.log('[CacheManager] clearBox error ($boxName): $e');
    }
  }

  /// Clear ALL cache boxes.
  static Future<void> clearAll() async {
    final boxes = [
      CacheConfig.coursesBox,
      CacheConfig.courseContentBox,
      CacheConfig.gradesBox,
      CacheConfig.calendarBox,
      CacheConfig.notificationsBox,
      CacheConfig.profileBox,
      CacheConfig.forumsBox,
    ];
    for (final name in boxes) {
      await clearBox(name);
    }
    dev.log('[CacheManager] All caches cleared');
  }

  // ─── Info ───

  /// Get total number of cached entries across all boxes.
  static int get totalEntries {
    int total = 0;
    for (final name in [
      CacheConfig.coursesBox,
      CacheConfig.courseContentBox,
      CacheConfig.gradesBox,
      CacheConfig.calendarBox,
      CacheConfig.notificationsBox,
      CacheConfig.profileBox,
      CacheConfig.forumsBox,
    ]) {
      try {
        total += Hive.box(name).length;
      } catch (_) {}
    }
    return total;
  }

  /// Get estimated cache size in bytes (based on stored data).
  static int get estimatedSizeBytes {
    int size = 0;
    for (final name in [
      CacheConfig.coursesBox,
      CacheConfig.courseContentBox,
      CacheConfig.gradesBox,
      CacheConfig.calendarBox,
      CacheConfig.notificationsBox,
      CacheConfig.profileBox,
      CacheConfig.forumsBox,
    ]) {
      try {
        final box = Hive.box(name);
        for (var i = 0; i < box.length; i++) {
          final val = box.getAt(i);
          if (val is Map) {
            size += (val['data'] as String? ?? '').length;
          }
        }
      } catch (_) {}
    }
    return size;
  }

  /// Remove all expired entries from all boxes.
  static Future<int> cleanExpired({
    Duration ttl = CacheConfig.defaultTTL,
  }) async {
    int cleaned = 0;
    for (final name in [
      CacheConfig.coursesBox,
      CacheConfig.courseContentBox,
      CacheConfig.gradesBox,
      CacheConfig.calendarBox,
      CacheConfig.notificationsBox,
      CacheConfig.profileBox,
      CacheConfig.forumsBox,
    ]) {
      try {
        final box = Hive.box(name);
        final keysToDelete = <dynamic>[];
        for (final key in box.keys) {
          final raw = box.get(key);
          if (raw is Map) {
            final entry = CacheEntry.fromMap(raw);
            if (entry.isExpired(ttl)) {
              keysToDelete.add(key);
            }
          }
        }
        if (keysToDelete.isNotEmpty) {
          await box.deleteAll(keysToDelete);
          cleaned += keysToDelete.length;
        }
      } catch (_) {}
    }
    if (cleaned > 0) {
      dev.log('[CacheManager] Cleaned $cleaned expired entries');
    }
    return cleaned;
  }
}
