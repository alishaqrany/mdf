/// Configuration for the Hive-based caching system.
class CacheConfig {
  CacheConfig._();

  // ─── Box Names ───
  static const String coursesBox = 'courses_cache';
  static const String courseContentBox = 'course_content_cache';
  static const String gradesBox = 'grades_cache';
  static const String calendarBox = 'calendar_cache';
  static const String notificationsBox = 'notifications_cache';
  static const String profileBox = 'profile_cache';
  static const String forumsBox = 'forums_cache';
  static const String downloadsBox = 'downloads_meta';
  static const String offlineQueueBox = 'offline_queue';

  // ─── TTL Durations ───
  /// Default cache time-to-live: 1 hour.
  static const Duration defaultTTL = Duration(hours: 1);

  /// Short cache for frequently changing data (notifications, messages): 15 min.
  static const Duration shortTTL = Duration(minutes: 15);

  /// Long cache for rarely changing data (profile, course structure): 1 day.
  static const Duration longTTL = Duration(days: 1);

  /// Very long cache for downloaded content (offline access): 30 days.
  static const Duration downloadTTL = Duration(days: 30);

  // ─── Limits ───
  /// Maximum cache size per box (in entries). 0 = unlimited.
  static const int maxEntriesPerBox = 500;

  /// Maximum total cache storage size (bytes). ~50 MB.
  static const int maxCacheSizeBytes = 50 * 1024 * 1024;
}
