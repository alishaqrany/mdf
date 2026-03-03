import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Platform detection utilities for conditional logic.
class PlatformInfo {
  PlatformInfo._();

  /// true when running as a Flutter‑Web build.
  static bool get isWeb => kIsWeb;

  /// true on physical / emulated Android.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// true on physical / emulated iOS.
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// true on Windows desktop.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// true on macOS desktop.
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// true on Linux desktop.
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  /// true for any mobile platform (Android or iOS).
  static bool get isMobile => isAndroid || isIOS;

  /// true for any desktop platform (Windows, macOS, or Linux).
  static bool get isDesktop => isWindows || isMacOS || isLinux;

  /// Human-readable platform name.
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  /// true when WebView is natively supported.
  static bool get supportsWebView => isMobile;

  /// true when native file system access is available.
  static bool get supportsFileSystem => !isWeb;

  /// true when push notifications are natively supported.
  static bool get supportsPushNotifications => isMobile;

  /// true when home‑screen widgets are supported.
  static bool get supportsHomeWidget => isMobile;
}
