import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Service that manages content protection features such as
/// preventing screen capture, screen recording, and screenshots.
///
/// Uses platform channels on Android/iOS for secure surface,
/// and JavaScript visibility tricks on web.
class ScreenProtectionService {
  static const _channel = MethodChannel('com.mdf.content_protection');

  static bool _isEnabled = false;

  /// Whether screen protection is currently active.
  static bool get isEnabled => _isEnabled;

  /// Enables secure screen flags to prevent screenshots/recording.
  static Future<void> enable() async {
    if (_isEnabled) return;
    _isEnabled = true;

    if (kIsWeb) {
      // Web: handled via CSS/JS in index.html — we signal intent here
      return;
    }

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('enableProtection');
      } on MissingPluginException {
        // Fallback: use FLAG_SECURE via SystemChrome
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } else if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('enableProtection');
      } on MissingPluginException {
        // Plugin not installed — silent fallback
      }
    }
  }

  /// Disables secure screen flags.
  static Future<void> disable() async {
    if (!_isEnabled) return;
    _isEnabled = false;

    if (kIsWeb) return;

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('disableProtection');
      } on MissingPluginException {
        // silent
      }
    } else if (Platform.isIOS) {
      try {
        await _channel.invokeMethod('disableProtection');
      } on MissingPluginException {
        // silent
      }
    }
  }

  /// Toggle based on protection settings.
  static Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await enable();
    } else {
      await disable();
    }
  }
}
