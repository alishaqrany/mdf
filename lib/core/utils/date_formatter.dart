import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Date/time formatting utilities.
class DateFormatter {
  DateFormatter._();

  /// Format timestamp (seconds) to readable date.
  static String formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format timestamp to date and time.
  static String formatDateTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Format timestamp to time only.
  static String formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('hh:mm a').format(date);
  }

  /// Format as relative time (e.g., "2 hours ago").
  static String formatRelative(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return timeago.format(date);
  }

  /// Format duration in seconds to HH:MM:SS.
  static String formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Format duration to human-readable string.
  static String formatDurationHuman(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;

    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}m';
    return '${seconds}s';
  }

  /// Check if timestamp is in the past.
  static bool isPast(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return date.isBefore(DateTime.now());
  }

  /// Check if timestamp is today.
  static bool isToday(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
