import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../platform/platform_info.dart';
import 'white_label_config.dart';

/// Resolves which [WhiteLabelConfig] should be used for the current session.
///
/// Resolution order:
/// 1. **Web** — reads the tenant slug from the URL hostname/path
///    (e.g. `tenant1.mdf.app` or `mdf.app/tenant1`).
/// 2. **Mobile / Desktop** — reads from an embedded JSON asset
///    (`assets/config/tenant.json`), or falls back to the default config.
/// 3. A previously-saved tenant in [SharedPreferences] overrides (2).
class TenantResolver {
  static const _prefsKey = '__mdf_current_tenant';
  final SharedPreferences _prefs;

  TenantResolver({required SharedPreferences prefs}) : _prefs = prefs;

  /// Resolve the current tenant's configuration.
  Future<WhiteLabelConfig> resolve() async {
    // 1. Check if the user previously selected a tenant
    final savedJson = _prefs.getString(_prefsKey);
    if (savedJson != null) {
      try {
        final map = jsonDecode(savedJson) as Map<String, dynamic>;
        return WhiteLabelConfig.fromJson(map);
      } catch (_) {
        // Corrupted data — continue to other methods
      }
    }

    // 2. Web: attempt to derive tenant from the URL
    if (PlatformInfo.isWeb) {
      final webConfig = _resolveFromWebUrl();
      if (webConfig != null) return webConfig;
    }

    // 3. Try loading from bundled JSON asset
    try {
      final jsonString = await rootBundle.loadString(
        'assets/config/tenant.json',
      );
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return WhiteLabelConfig.fromJson(map);
    } catch (_) {
      // No bundled config — use default
    }

    return WhiteLabelConfig.defaultConfig;
  }

  /// Persist the active tenant so it survives restarts.
  Future<void> saveTenant(WhiteLabelConfig config) async {
    await _prefs.setString(_prefsKey, jsonEncode(config.toJson()));
  }

  /// Clear saved tenant (reset to default).
  Future<void> clearTenant() async {
    await _prefs.remove(_prefsKey);
  }

  /// Attempt to parse the tenant slug from the web URL.
  ///
  /// Supports:
  /// - Subdomain: `tenant1.mdf.app` → tenant1
  /// - Path prefix: `mdf.app/tenant1/...` → tenant1
  WhiteLabelConfig? _resolveFromWebUrl() {
    // On web, we'd read from Uri.base. For now return null
    // so we fall through to the asset config.
    // In production, implement:
    //   final host = Uri.base.host; // e.g. tenant1.mdf.app
    //   final slug = host.split('.').first;
    //   return _fetchRemoteConfig(slug);
    return null;
  }
}

/// Holds the active tenant configuration as a singleton.
///
/// Set once at app startup, then accessed throughout the app via
/// `TenantManager.current`.
class TenantManager {
  TenantManager._();

  static WhiteLabelConfig _current = WhiteLabelConfig.defaultConfig;

  /// The current tenant configuration.
  static WhiteLabelConfig get current => _current;

  /// Whether a non-default tenant is active.
  static bool get isCustomTenant => _current.tenantId != 'mdf_default';

  /// Initialise with the resolved config.
  static void init(WhiteLabelConfig config) {
    _current = config;
    debugPrint(
      '[TenantManager] Active tenant: ${config.tenantId} '
      '(${config.appName})',
    );
  }

  /// Switch to a different tenant at runtime.
  static void switchTenant(WhiteLabelConfig config) {
    _current = config;
    debugPrint('[TenantManager] Switched to: ${config.tenantId}');
  }
}
