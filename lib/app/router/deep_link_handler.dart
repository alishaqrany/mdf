import 'package:go_router/go_router.dart';

/// Handles incoming deep links (App Links / Custom Scheme) and maps
/// them to internal GoRouter paths.
///
/// Supported URI patterns:
///  - https://moodle.example.com/course/view.php?id=123
///  - https://moodle.example.com/mod/quiz/view.php?id=456
///  - https://moodle.example.com/user/profile.php?id=789
///  - mdf://open/course/123
///  - mdf://open/grades
///  - mdf://open/messages
///  - mdf://open/notifications
class DeepLinkHandler {
  /// Called by GoRouter's redirect — returns a new path if the current
  /// URI is a deep link, or `null` to let normal routing proceed.
  static String? resolve(GoRouterState state) {
    final uri = state.uri;

    // ─── Custom scheme: mdf://open/... ───
    if (uri.scheme == 'mdf') {
      return _handleCustomScheme(uri);
    }

    // ─── App Link: https://moodle.example.com/... ───
    if (uri.host == 'moodle.example.com') {
      return _handleAppLink(uri);
    }

    return null;
  }

  static String? _handleCustomScheme(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return '/student';

    switch (segments.first) {
      case 'course':
        if (segments.length >= 2) {
          final id = segments[1];
          return '/student/course/$id';
        }
        return '/student/courses';
      case 'grades':
        return '/student/grades';
      case 'messages':
        return '/student/messages';
      case 'notifications':
        return '/student/notifications';
      case 'calendar':
        return '/student/calendar';
      case 'search':
        return '/student/search';
      default:
        return '/student';
    }
  }

  static String? _handleAppLink(Uri uri) {
    final path = uri.path;
    final params = uri.queryParameters;

    // /course/view.php?id=123
    if (path.startsWith('/course/view.php')) {
      final id = params['id'];
      if (id != null) return '/student/course/$id';
      return '/student/courses';
    }

    // /mod/quiz/view.php?id=456
    if (path.startsWith('/mod/quiz')) {
      return '/student/courses'; // open courses and let user navigate
    }

    // /user/profile.php?id=789
    if (path.startsWith('/user/profile.php')) {
      return '/student/profile';
    }

    return null;
  }
}
