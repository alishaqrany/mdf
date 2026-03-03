import 'package:flutter_test/flutter_test.dart';
import 'package:mdf_app/core/config/white_label_config.dart';
import 'package:mdf_app/core/config/tenant_config.dart';
import 'package:mdf_app/core/config/tenant_resolver.dart';

import 'package:flutter/material.dart';

import '../../helpers/test_helpers.dart';

void main() {
  // ═════════════════════════════════════════════
  //  WhiteLabelConfig
  // ═════════════════════════════════════════════
  group('WhiteLabelConfig', () {
    test('defaultConfig has correct values', () {
      const config = WhiteLabelConfig.defaultConfig;
      expect(config.tenantId, 'mdf_default');
      expect(config.appName, 'MDF Academy');
      expect(config.tagline, 'Modern Educational Platform');
      expect(config.moodleBaseUrl, '');
      expect(config.primaryColor, const Color(0xFF6C63FF));
      expect(config.secondaryColor, const Color(0xFF03DAC5));
      expect(config.accentColor, const Color(0xFFFFC107));
    });

    test('fromJson parses hex colors correctly', () {
      final config = WhiteLabelConfig.fromJson(TestFixtures.tWhiteLabelJson);
      expect(config.tenantId, 'university_a');
      expect(config.appName, 'UniApp');
      expect(config.tagline, 'Learn More');
      expect(config.moodleBaseUrl, 'https://lms.university.edu');
      expect(config.moodleService, 'university_service');
      expect(config.primaryColor, const Color(0xFFFF5722));
      expect(config.secondaryColor, const Color(0xFF2196F3));
      expect(config.accentColor, const Color(0xFFFFC107));
      expect(config.logoUrl, 'https://cdn.university.edu/logo.png');
      expect(config.defaultLocale, 'en');
      expect(config.supportedLocales, ['en', 'ar', 'fr']);
      expect(config.termsUrl, 'https://university.edu/terms');
      expect(config.privacyUrl, 'https://university.edu/privacy');
      expect(config.supportEmail, 'support@university.edu');
    });

    test('fromJson with missing fields uses defaults', () {
      final config = WhiteLabelConfig.fromJson(const <String, dynamic>{});
      expect(config.tenantId, 'default');
      expect(config.appName, 'MDF Academy');
      expect(config.moodleBaseUrl, '');
      expect(config.moodleService, 'mdf_mobile_service');
      expect(config.supportedLocales, ['ar', 'en']);
    });

    test('fromJson parses integer color values', () {
      final config = WhiteLabelConfig.fromJson(const {
        'tenant_id': 'test',
        'app_name': 'Test',
        'moodle_base_url': '',
        'primary_color': 0xFF00FF00,
      });
      expect(config.primaryColor, const Color(0xFF00FF00));
    });

    test('toJson produces valid JSON', () {
      final config = WhiteLabelConfig.fromJson(TestFixtures.tWhiteLabelJson);
      final json = config.toJson();
      expect(json['tenant_id'], 'university_a');
      expect(json['app_name'], 'UniApp');
      expect(json['moodle_base_url'], 'https://lms.university.edu');
      expect(json['primary_color'], isA<String>());
      expect(json['features'], isA<Map>());
    });

    test('toJson → fromJson roundtrip preserves data', () {
      final original = WhiteLabelConfig.fromJson(TestFixtures.tWhiteLabelJson);
      final json = original.toJson();
      final restored = WhiteLabelConfig.fromJson(json);
      expect(restored.tenantId, original.tenantId);
      expect(restored.appName, original.appName);
      expect(restored.moodleBaseUrl, original.moodleBaseUrl);
      expect(restored.supportedLocales, original.supportedLocales);
      expect(restored.features.enableSocial, original.features.enableSocial);
    });

    test('copyWith overrides selected fields', () {
      const config = WhiteLabelConfig(
        tenantId: 'original',
        appName: 'Original App',
        moodleBaseUrl: 'https://original.edu',
        primaryColor: Color(0xFF000000),
      );

      final modified = config.copyWith(
        appName: 'Modified App',
        primaryColor: const Color(0xFFFF0000),
      );

      expect(modified.tenantId, 'original'); // unchanged
      expect(modified.appName, 'Modified App'); // changed
      expect(modified.moodleBaseUrl, 'https://original.edu'); // unchanged
      expect(modified.primaryColor, const Color(0xFFFF0000)); // changed
    });

    test('copyWith with no arguments returns equivalent object', () {
      const original = WhiteLabelConfig(
        tenantId: 'test',
        appName: 'Test',
        moodleBaseUrl: '',
        primaryColor: Color(0xFF123456),
      );
      final copy = original.copyWith();
      expect(copy.tenantId, original.tenantId);
      expect(copy.appName, original.appName);
      expect(copy.primaryColor, original.primaryColor);
    });
  });

  // ═════════════════════════════════════════════
  //  TenantFeatureFlags
  // ═════════════════════════════════════════════
  group('TenantFeatureFlags', () {
    test('default constructor enables all flags', () {
      const flags = TenantFeatureFlags();
      expect(flags.enableAi, true);
      expect(flags.enableSocial, true);
      expect(flags.enableGamification, true);
      expect(flags.enableForums, true);
      expect(flags.enableVideoMeetings, true);
      expect(flags.enableDownloads, true);
      expect(flags.enableSearch, true);
      expect(flags.enableCalendar, true);
      expect(flags.enableNotifications, true);
      expect(flags.enableMessaging, true);
      expect(flags.enableGrades, true);
      expect(flags.enableQuizzes, true);
      expect(flags.enableAssignments, true);
      expect(flags.enableEnrollment, true);
      expect(flags.enableUserManagement, true);
      expect(flags.enableDarkMode, true);
    });

    test('fromJson parses disabled features', () {
      final flags = TenantFeatureFlags.fromJson(
        (TestFixtures.tWhiteLabelJson['features'] as Map<String, dynamic>),
      );
      expect(flags.enableAi, true);
      expect(flags.enableSocial, false);
      expect(flags.enableVideoMeetings, false);
      expect(flags.enableUserManagement, false);
    });

    test('fromJson with empty map defaults to all enabled', () {
      final flags = TenantFeatureFlags.fromJson(const {});
      expect(flags.enableAi, true);
      expect(flags.enableSocial, true);
      expect(flags.enableGamification, true);
    });

    test('toJson produces correct keys', () {
      const flags = TenantFeatureFlags(enableAi: false, enableDarkMode: false);
      final json = flags.toJson();
      expect(json['enable_ai'], false);
      expect(json['enable_dark_mode'], false);
      expect(json['enable_social'], true); // default
      expect(json.length, 16);
    });

    test('toJson → fromJson roundtrip', () {
      const original = TenantFeatureFlags(
        enableAi: false,
        enableSocial: false,
        enableGamification: true,
      );
      final json = original.toJson();
      final restored = TenantFeatureFlags.fromJson(json);
      expect(restored.enableAi, original.enableAi);
      expect(restored.enableSocial, original.enableSocial);
      expect(restored.enableGamification, original.enableGamification);
    });
  });

  // ═════════════════════════════════════════════
  //  TenantConfig
  // ═════════════════════════════════════════════
  group('TenantConfig', () {
    test('defaultConfig has empty resolved URL', () {
      final config = TenantConfig.defaultConfig;
      expect(config.resolvedMoodleUrl, '');
      expect(config.maxUsers, 0);
      expect(config.storageQuotaBytes, 0);
      expect(config.isLicenseValid, true);
      expect(config.licenseExpiry, isNull);
      expect(config.customHeaders, isEmpty);
      expect(config.branding.tenantId, 'mdf_default');
    });

    test('fromJson parses all fields', () {
      final config = TenantConfig.fromJson(TestFixtures.tTenantConfigJson);
      expect(config.resolvedMoodleUrl, 'https://lms.university.edu');
      expect(config.maxUsers, 500);
      expect(config.storageQuotaBytes, 5368709120);
      expect(config.isLicenseValid, true);
      expect(config.licenseExpiry, isA<DateTime>());
      expect(config.licenseExpiry, DateTime.parse('2027-01-01T00:00:00.000'));
      expect(config.customHeaders['X-Tenant'], 'university_a');
      expect(config.branding.tenantId, 'university_a');
    });

    test('fromJson with missing fields uses defaults', () {
      final config = TenantConfig.fromJson(const {});
      expect(config.resolvedMoodleUrl, '');
      expect(config.maxUsers, 0);
      expect(config.isLicenseValid, true);
      expect(config.licenseExpiry, isNull);
      expect(config.branding.tenantId, 'mdf_default');
    });

    test('toJson produces expected structure', () {
      final config = TenantConfig.fromJson(TestFixtures.tTenantConfigJson);
      final json = config.toJson();
      expect(json['moodle_url'], 'https://lms.university.edu');
      expect(json['max_users'], 500);
      expect(json['is_license_valid'], true);
      expect(json['branding'], isA<Map>());
      expect(json['custom_headers'], isA<Map>());
    });

    test('toJson → fromJson roundtrip', () {
      final original = TenantConfig.fromJson(TestFixtures.tTenantConfigJson);
      final json = original.toJson();
      final restored = TenantConfig.fromJson(json);
      expect(restored.resolvedMoodleUrl, original.resolvedMoodleUrl);
      expect(restored.maxUsers, original.maxUsers);
      expect(restored.isLicenseValid, original.isLicenseValid);
      expect(restored.branding.tenantId, original.branding.tenantId);
    });
  });

  // ═════════════════════════════════════════════
  //  TenantManager
  // ═════════════════════════════════════════════
  group('TenantManager', () {
    tearDown(() {
      // Reset to default after each test
      TenantManager.init(WhiteLabelConfig.defaultConfig);
    });

    test('starts with defaultConfig', () {
      expect(TenantManager.current.tenantId, 'mdf_default');
      expect(TenantManager.isCustomTenant, false);
    });

    test('init sets current config', () {
      final custom = WhiteLabelConfig.fromJson(TestFixtures.tWhiteLabelJson);
      TenantManager.init(custom);
      expect(TenantManager.current.tenantId, 'university_a');
      expect(TenantManager.isCustomTenant, true);
    });

    test('switchTenant updates current', () {
      TenantManager.switchTenant(
        const WhiteLabelConfig(
          tenantId: 'tenant_b',
          appName: 'B App',
          moodleBaseUrl: '',
          primaryColor: Color(0xFF000000),
        ),
      );
      expect(TenantManager.current.tenantId, 'tenant_b');
      expect(TenantManager.current.appName, 'B App');
    });

    test('isCustomTenant returns false for mdf_default', () {
      TenantManager.init(WhiteLabelConfig.defaultConfig);
      expect(TenantManager.isCustomTenant, false);
    });

    test('isCustomTenant returns true for non-default tenant', () {
      TenantManager.init(
        const WhiteLabelConfig(
          tenantId: 'custom_123',
          appName: 'Custom',
          moodleBaseUrl: '',
          primaryColor: Color(0xFF000000),
        ),
      );
      expect(TenantManager.isCustomTenant, true);
    });
  });
}
