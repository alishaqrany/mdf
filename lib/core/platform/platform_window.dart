import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'platform_info.dart';

/// Desktop and web window configuration.
///
/// Sets up window sizing, title, and keyboard shortcuts
/// for non-mobile platforms.
class PlatformWindow {
  PlatformWindow._();

  /// Configure the window appropriately for the current platform.
  ///
  /// - Mobile: portrait-only, transparent status bar
  /// - Desktop: allow all orientations, set min size
  /// - Web: allow all orientations
  static Future<void> configure() async {
    if (PlatformInfo.isMobile) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );
    }

    // Desktop and web: allow all orientations
    if (PlatformInfo.isDesktop || PlatformInfo.isWeb) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// Keyboard shortcut intents for desktop / web.
  static Map<ShortcutActivator, Intent> get desktopShortcuts => {
    // Ctrl+K → Search
    const SingleActivator(LogicalKeyboardKey.keyK, control: true):
        const SearchIntent(),
    // Ctrl+N → New message
    const SingleActivator(LogicalKeyboardKey.keyN, control: true):
        const NewMessageIntent(),
    // Ctrl+D → Dashboard
    const SingleActivator(LogicalKeyboardKey.keyD, control: true):
        const DashboardIntent(),
    // Ctrl+Shift+S → Settings
    const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true):
        const SettingsIntent(),
    // F5 → Refresh
    const SingleActivator(LogicalKeyboardKey.f5): const RefreshIntent(),
  };
}

// ─── Intent definitions for keyboard shortcuts ───

class SearchIntent extends Intent {
  const SearchIntent();
}

class NewMessageIntent extends Intent {
  const NewMessageIntent();
}

class DashboardIntent extends Intent {
  const DashboardIntent();
}

class SettingsIntent extends Intent {
  const SettingsIntent();
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}
