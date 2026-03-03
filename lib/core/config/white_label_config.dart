import 'package:flutter/material.dart';

/// White-label configuration for a tenant/institution.
///
/// Each institution can customise branding, colours, features and
/// the Moodle server URL. The configuration can be loaded from a
/// JSON remote endpoint, a local JSON file, or compile-time constants.
class WhiteLabelConfig {
  /// Unique tenant identifier (slug).
  final String tenantId;

  /// Human-readable institution name.
  final String appName;

  /// Optional tagline.
  final String? tagline;

  /// Moodle server base URL (e.g. https://lms.university.edu).
  final String moodleBaseUrl;

  /// Moodle web-service name (defaults to mdf_mobile).
  final String moodleService;

  /// Primary brand colour.
  final Color primaryColor;

  /// Secondary brand colour.
  final Color secondaryColor;

  /// Accent / highlight colour.
  final Color accentColor;

  /// Surface colour override (card backgrounds etc.).
  final Color? surfaceColor;

  /// Background colour override.
  final Color? backgroundColor;

  /// URL or asset path for the logo (shown in login/splash).
  final String? logoUrl;

  /// URL for the favicon (web only).
  final String? faviconUrl;

  /// URL for the splash image.
  final String? splashImageUrl;

  /// Feature flags — disable features per tenant.
  final TenantFeatureFlags features;

  /// Custom locale overrides (e.g. force a specific default locale).
  final String? defaultLocale;

  /// Supported locales for this tenant.
  final List<String> supportedLocales;

  /// Custom terms-of-service URL.
  final String? termsUrl;

  /// Custom privacy-policy URL.
  final String? privacyUrl;

  /// Custom support/contact email.
  final String? supportEmail;

  const WhiteLabelConfig({
    required this.tenantId,
    required this.appName,
    this.tagline,
    required this.moodleBaseUrl,
    this.moodleService = 'mdf_mobile',
    required this.primaryColor,
    this.secondaryColor = const Color(0xFF03DAC5),
    this.accentColor = const Color(0xFFFFC107),
    this.surfaceColor,
    this.backgroundColor,
    this.logoUrl,
    this.faviconUrl,
    this.splashImageUrl,
    this.features = const TenantFeatureFlags(),
    this.defaultLocale,
    this.supportedLocales = const ['ar', 'en'],
    this.termsUrl,
    this.privacyUrl,
    this.supportEmail,
  });

  /// The default MDF Academy configuration.
  static const defaultConfig = WhiteLabelConfig(
    tenantId: 'mdf_default',
    appName: 'MDF Academy',
    tagline: 'Modern Educational Platform',
    moodleBaseUrl: '',
    primaryColor: Color(0xFF6C63FF),
    secondaryColor: Color(0xFF03DAC5),
    accentColor: Color(0xFFFFC107),
  );

  /// Create from a JSON map (e.g. fetched from API).
  factory WhiteLabelConfig.fromJson(Map<String, dynamic> json) {
    Color parseColor(dynamic value, Color fallback) {
      if (value is String && value.startsWith('#')) {
        return Color(int.parse('FF${value.substring(1)}', radix: 16));
      }
      if (value is int) return Color(value);
      return fallback;
    }

    return WhiteLabelConfig(
      tenantId: json['tenant_id'] as String? ?? 'default',
      appName: json['app_name'] as String? ?? 'MDF Academy',
      tagline: json['tagline'] as String?,
      moodleBaseUrl: json['moodle_base_url'] as String? ?? '',
      moodleService: json['moodle_service'] as String? ?? 'mdf_mobile',
      primaryColor: parseColor(json['primary_color'], const Color(0xFF6C63FF)),
      secondaryColor: parseColor(
        json['secondary_color'],
        const Color(0xFF03DAC5),
      ),
      accentColor: parseColor(json['accent_color'], const Color(0xFFFFC107)),
      surfaceColor: json['surface_color'] != null
          ? parseColor(json['surface_color'], Colors.white)
          : null,
      backgroundColor: json['background_color'] != null
          ? parseColor(json['background_color'], Colors.white)
          : null,
      logoUrl: json['logo_url'] as String?,
      faviconUrl: json['favicon_url'] as String?,
      splashImageUrl: json['splash_image_url'] as String?,
      features: json['features'] != null
          ? TenantFeatureFlags.fromJson(
              json['features'] as Map<String, dynamic>,
            )
          : const TenantFeatureFlags(),
      defaultLocale: json['default_locale'] as String?,
      supportedLocales:
          (json['supported_locales'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['ar', 'en'],
      termsUrl: json['terms_url'] as String?,
      privacyUrl: json['privacy_url'] as String?,
      supportEmail: json['support_email'] as String?,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
    'tenant_id': tenantId,
    'app_name': appName,
    'tagline': tagline,
    'moodle_base_url': moodleBaseUrl,
    'moodle_service': moodleService,
    'primary_color': '#${primaryColor.value.toRadixString(16).substring(2)}',
    'secondary_color':
        '#${secondaryColor.value.toRadixString(16).substring(2)}',
    'accent_color': '#${accentColor.value.toRadixString(16).substring(2)}',
    'surface_color': surfaceColor != null
        ? '#${surfaceColor!.value.toRadixString(16).substring(2)}'
        : null,
    'background_color': backgroundColor != null
        ? '#${backgroundColor!.value.toRadixString(16).substring(2)}'
        : null,
    'logo_url': logoUrl,
    'favicon_url': faviconUrl,
    'splash_image_url': splashImageUrl,
    'features': features.toJson(),
    'default_locale': defaultLocale,
    'supported_locales': supportedLocales,
    'terms_url': termsUrl,
    'privacy_url': privacyUrl,
    'support_email': supportEmail,
  };

  /// Create a copy with overrides.
  WhiteLabelConfig copyWith({
    String? tenantId,
    String? appName,
    String? tagline,
    String? moodleBaseUrl,
    String? moodleService,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? surfaceColor,
    Color? backgroundColor,
    String? logoUrl,
    String? faviconUrl,
    String? splashImageUrl,
    TenantFeatureFlags? features,
    String? defaultLocale,
    List<String>? supportedLocales,
    String? termsUrl,
    String? privacyUrl,
    String? supportEmail,
  }) {
    return WhiteLabelConfig(
      tenantId: tenantId ?? this.tenantId,
      appName: appName ?? this.appName,
      tagline: tagline ?? this.tagline,
      moodleBaseUrl: moodleBaseUrl ?? this.moodleBaseUrl,
      moodleService: moodleService ?? this.moodleService,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      logoUrl: logoUrl ?? this.logoUrl,
      faviconUrl: faviconUrl ?? this.faviconUrl,
      splashImageUrl: splashImageUrl ?? this.splashImageUrl,
      features: features ?? this.features,
      defaultLocale: defaultLocale ?? this.defaultLocale,
      supportedLocales: supportedLocales ?? this.supportedLocales,
      termsUrl: termsUrl ?? this.termsUrl,
      privacyUrl: privacyUrl ?? this.privacyUrl,
      supportEmail: supportEmail ?? this.supportEmail,
    );
  }
}

/// Feature toggles per tenant — allows disabling features
/// for institutions that don't need them.
class TenantFeatureFlags {
  final bool enableAi;
  final bool enableSocial;
  final bool enableGamification;
  final bool enableForums;
  final bool enableVideoMeetings;
  final bool enableDownloads;
  final bool enableSearch;
  final bool enableCalendar;
  final bool enableNotifications;
  final bool enableMessaging;
  final bool enableGrades;
  final bool enableQuizzes;
  final bool enableAssignments;
  final bool enableEnrollment;
  final bool enableUserManagement;
  final bool enableDarkMode;

  const TenantFeatureFlags({
    this.enableAi = true,
    this.enableSocial = true,
    this.enableGamification = true,
    this.enableForums = true,
    this.enableVideoMeetings = true,
    this.enableDownloads = true,
    this.enableSearch = true,
    this.enableCalendar = true,
    this.enableNotifications = true,
    this.enableMessaging = true,
    this.enableGrades = true,
    this.enableQuizzes = true,
    this.enableAssignments = true,
    this.enableEnrollment = true,
    this.enableUserManagement = true,
    this.enableDarkMode = true,
  });

  factory TenantFeatureFlags.fromJson(Map<String, dynamic> json) {
    return TenantFeatureFlags(
      enableAi: json['enable_ai'] as bool? ?? true,
      enableSocial: json['enable_social'] as bool? ?? true,
      enableGamification: json['enable_gamification'] as bool? ?? true,
      enableForums: json['enable_forums'] as bool? ?? true,
      enableVideoMeetings: json['enable_video_meetings'] as bool? ?? true,
      enableDownloads: json['enable_downloads'] as bool? ?? true,
      enableSearch: json['enable_search'] as bool? ?? true,
      enableCalendar: json['enable_calendar'] as bool? ?? true,
      enableNotifications: json['enable_notifications'] as bool? ?? true,
      enableMessaging: json['enable_messaging'] as bool? ?? true,
      enableGrades: json['enable_grades'] as bool? ?? true,
      enableQuizzes: json['enable_quizzes'] as bool? ?? true,
      enableAssignments: json['enable_assignments'] as bool? ?? true,
      enableEnrollment: json['enable_enrollment'] as bool? ?? true,
      enableUserManagement: json['enable_user_management'] as bool? ?? true,
      enableDarkMode: json['enable_dark_mode'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'enable_ai': enableAi,
    'enable_social': enableSocial,
    'enable_gamification': enableGamification,
    'enable_forums': enableForums,
    'enable_video_meetings': enableVideoMeetings,
    'enable_downloads': enableDownloads,
    'enable_search': enableSearch,
    'enable_calendar': enableCalendar,
    'enable_notifications': enableNotifications,
    'enable_messaging': enableMessaging,
    'enable_grades': enableGrades,
    'enable_quizzes': enableQuizzes,
    'enable_assignments': enableAssignments,
    'enable_enrollment': enableEnrollment,
    'enable_user_management': enableUserManagement,
    'enable_dark_mode': enableDarkMode,
  };
}
