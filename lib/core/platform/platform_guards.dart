import 'platform_info.dart';
import 'package:flutter/foundation.dart';

/// Guards that conditionally run platform-specific code.
///
/// Use these wrappers to avoid importing packages that are
/// unavailable on certain platforms (e.g. home_widget on web).
class PlatformGuards {
  PlatformGuards._();

  /// Execute [action] only on mobile (Android/iOS).
  static Future<T?> onMobile<T>(Future<T> Function() action) async {
    if (PlatformInfo.isMobile) return action();
    return null;
  }

  /// Execute [action] only on desktop (Windows/macOS/Linux).
  static Future<T?> onDesktop<T>(Future<T> Function() action) async {
    if (PlatformInfo.isDesktop) return action();
    return null;
  }

  /// Execute [action] only on web.
  static Future<T?> onWeb<T>(Future<T> Function() action) async {
    if (PlatformInfo.isWeb) return action();
    return null;
  }

  /// Execute [action] only when file system is available.
  static Future<T?> withFileSystem<T>(Future<T> Function() action) async {
    if (PlatformInfo.supportsFileSystem) return action();
    return null;
  }

  /// Log a message when a feature is skipped on the current platform.
  static void logSkipped(String feature) {
    debugPrint(
      '[PlatformGuards] "$feature" skipped — '
      'not supported on ${PlatformInfo.platformName}',
    );
  }
}
