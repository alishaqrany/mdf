import 'white_label_config.dart';

/// Tenant-specific runtime configuration.
///
/// Extends [WhiteLabelConfig] with runtime state such as
/// the resolved Moodle base URL, active user count, etc.
class TenantConfig {
  /// The underlying white-label branding config.
  final WhiteLabelConfig branding;

  /// Resolved and validated Moodle base URL (no trailing slash).
  final String resolvedMoodleUrl;

  /// Maximum number of concurrent users (0 = unlimited).
  final int maxUsers;

  /// Tenant storage quota in bytes (0 = unlimited).
  final int storageQuotaBytes;

  /// Whether the tenant license is currently valid.
  final bool isLicenseValid;

  /// License expiry date (null = perpetual).
  final DateTime? licenseExpiry;

  /// Custom API headers to include with every request for this tenant.
  final Map<String, String> customHeaders;

  const TenantConfig({
    required this.branding,
    required this.resolvedMoodleUrl,
    this.maxUsers = 0,
    this.storageQuotaBytes = 0,
    this.isLicenseValid = true,
    this.licenseExpiry,
    this.customHeaders = const {},
  });

  /// Default config.
  static TenantConfig get defaultConfig => const TenantConfig(
    branding: WhiteLabelConfig.defaultConfig,
    resolvedMoodleUrl: '',
  );

  /// Create from JSON (API response).
  factory TenantConfig.fromJson(Map<String, dynamic> json) {
    return TenantConfig(
      branding: json['branding'] != null
          ? WhiteLabelConfig.fromJson(json['branding'] as Map<String, dynamic>)
          : WhiteLabelConfig.defaultConfig,
      resolvedMoodleUrl: json['moodle_url'] as String? ?? '',
      maxUsers: json['max_users'] as int? ?? 0,
      storageQuotaBytes: json['storage_quota_bytes'] as int? ?? 0,
      isLicenseValid: json['is_license_valid'] as bool? ?? true,
      licenseExpiry: json['license_expiry'] != null
          ? DateTime.tryParse(json['license_expiry'] as String)
          : null,
      customHeaders:
          (json['custom_headers'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'branding': branding.toJson(),
    'moodle_url': resolvedMoodleUrl,
    'max_users': maxUsers,
    'storage_quota_bytes': storageQuotaBytes,
    'is_license_valid': isLicenseValid,
    'license_expiry': licenseExpiry?.toIso8601String(),
    'custom_headers': customHeaders,
  };
}
