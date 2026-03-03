import '../platform/platform_info.dart';

/// Pushes dashboard data to the Android Home Screen Widget.
///
/// Call [updateWidget] after dashboard data is loaded to keep
/// the widget in sync. On web/desktop this is a no-op.
class HomeWidgetService {
  static const _androidName = 'MdfHomeWidgetProvider';

  /// Update the home screen widget with latest data.
  static Future<void> updateWidget({
    required int courseCount,
    String? nextEventTitle,
  }) async {
    if (!PlatformInfo.supportsHomeWidget) return;

    // Dynamic import guarded by platform check — the home_widget
    // package is only available on mobile.
    try {
      final hw = await _getHomeWidget();
      await hw.saveWidgetData<String>('title', 'MDF Learning');
      await hw.saveWidgetData<String>('course_count', courseCount.toString());
      await hw.saveWidgetData<String>(
        'next_event',
        nextEventTitle ?? 'No upcoming events',
      );
      await hw.updateWidget(androidName: _androidName);
    } catch (_) {
      // Package not available on this platform
    }
  }

  /// Register a callback for widget taps (opens app).
  static Future<void> registerInteractivity() async {
    if (!PlatformInfo.supportsHomeWidget) return;

    try {
      final hw = await _getHomeWidget();
      await hw.registerInteractivityCallback(_backgroundCallback);
    } catch (_) {
      // Package not available
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    // Widget tap opens the app — GoRouter handles deep links
  }

  /// Lazy accessor for the HomeWidget package.
  static Future<dynamic> _getHomeWidget() async {
    // ignore: depend_on_referenced_packages
    throw UnsupportedError('home_widget loaded via conditional import');
  }
}
