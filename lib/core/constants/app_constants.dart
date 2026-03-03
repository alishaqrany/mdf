// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'MDF Academy';
  static const String appVersion = '1.0.0';

  // Moodle API
  static const String moodleRestPath = '/webservice/rest/server.php';
  static const String moodleLoginPath = '/login/token.php';
  static const String moodleUploadPath = '/webservice/upload.php';
  static const String moodlePluginFilePath = '/webservice/pluginfile.php';
  static const String moodleService = 'mdf_mobile';
  static const String moodleRestFormat = 'json';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String privateTokenKey = 'private_token';
  static const String serverUrlKey = 'server_url';
  static const String userDataKey = 'user_data';
  static const String serviceNameKey = 'service_shortname';
  static const String themeKey = 'theme_mode';
  static const String localeKey = 'locale';
  static const String onboardingKey = 'onboarding_completed';
  static const String rememberMeKey = 'remember_me';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache durations
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration shortCacheDuration = Duration(minutes: 15);
  static const Duration longCacheDuration = Duration(days: 1);

  // Quiz auto-save interval
  static const Duration quizAutoSaveInterval = Duration(seconds: 30);

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
}
