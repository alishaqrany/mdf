import 'package:home_widget/home_widget.dart';

/// Pushes dashboard data to the Android Home Screen Widget.
///
/// Call [updateWidget] after dashboard data is loaded to keep
/// the widget in sync.
class HomeWidgetService {
  static const _androidName = 'MdfHomeWidgetProvider';

  /// Update the home screen widget with latest data.
  static Future<void> updateWidget({
    required int courseCount,
    String? nextEventTitle,
  }) async {
    await HomeWidget.saveWidgetData<String>('title', 'MDF Learning');
    await HomeWidget.saveWidgetData<String>(
      'course_count',
      courseCount.toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'next_event',
      nextEventTitle ?? 'No upcoming events',
    );
    await HomeWidget.updateWidget(androidName: _androidName);
  }

  /// Register a callback for widget taps (opens app).
  static Future<void> registerInteractivity() async {
    await HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    // Widget tap opens the app — GoRouter handles deep links
  }
}
