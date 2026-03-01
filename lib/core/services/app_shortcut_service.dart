import 'package:flutter/material.dart';

/// Manages App Shortcuts (long-press launcher icon actions).
///
/// On Android, static shortcuts are defined in `res/xml/shortcuts.xml`.
/// This service handles the incoming deep link when a shortcut is tapped.
///
/// For dynamic shortcuts or iOS Quick Actions, integrate
/// the `quick_actions` package here.
class AppShortcutService {
  /// Call once at app startup to handle the initial deep link
  /// that may come from an app shortcut tap.
  static void handleInitialShortcut(BuildContext context) {
    // GoRouter already handles `mdf://open/...` URIs from shortcuts.
    // This method is a hook for future dynamic shortcut registration.
  }

  /// Map of shortcut IDs to their route paths.
  static const Map<String, String> shortcuts = {
    'my_courses': '/student/courses',
    'messages': '/student/messages',
    'grades': '/student/grades',
    'search': '/student/search',
  };

  /// Resolve a shortcut ID to a GoRouter path.
  static String? resolvePath(String shortcutId) => shortcuts[shortcutId];
}
