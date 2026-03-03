import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Security utilities for the MDF app.
///
/// Provides input validation, URL security checks,
/// and safe logging helpers.
class SecurityUtils {
  SecurityUtils._();

  /// Ensures a URL uses HTTPS. Returns null if the URL cannot be secured.
  ///
  /// - Upgrades `http://` to `https://`
  /// - Prepends `https://` if no scheme
  /// - Returns null for empty/invalid URLs
  static String? enforceHttps(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('https://')) return trimmed;
    if (trimmed.startsWith('http://')) {
      return trimmed.replaceFirst('http://', 'https://');
    }
    return 'https://$trimmed';
  }

  /// Returns true if the URL uses HTTPS.
  static bool isSecureUrl(String url) {
    return url.startsWith('https://');
  }

  /// Sanitizes user input to prevent basic injection attacks.
  ///
  /// Removes HTML tags and dangerous characters.
  static String sanitizeInput(String input) {
    // Remove HTML tags
    final noHtml = input.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove script-related patterns
    final noScript = noHtml.replaceAll(
      RegExp(r'(javascript|onerror|onload|onclick|onfocus):', caseSensitive: false),
      '',
    );
    return noScript.trim();
  }

  /// Strips the Moodle token from a URL for safe logging.
  ///
  /// Replaces `token=xxxx` and `wstoken=xxxx` with `token=***`.
  static String maskTokenInUrl(String url) {
    return url
        .replaceAll(RegExp(r'token=[^&]+'), 'token=***')
        .replaceAll(RegExp(r'wstoken=[^&]+'), 'wstoken=***');
  }

  /// Log a message only in debug mode. No-op in release.
  static void debugLog(String tag, String message) {
    if (kDebugMode) {
      dev.log('[$tag] $message');
    }
  }

  /// Validates that a domain name follows basic format rules.
  static bool isValidDomain(String domain) {
    final regex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$',
    );
    return regex.hasMatch(domain);
  }

  /// Checks if the given URL is within the allowed Moodle domain.
  ///
  /// Used by WebView navigation delegates to prevent navigating
  /// to untrusted origins.
  static bool isAllowedOrigin(String url, String moodleBaseUrl) {
    try {
      final allowedUri = Uri.parse(moodleBaseUrl);
      final targetUri = Uri.parse(url);
      final allowedHost = allowedUri.host;
      final targetHost = targetUri.host;
      if (allowedHost.isEmpty || targetHost.isEmpty) return false;
      return targetHost == allowedHost || targetHost.endsWith('.$allowedHost');
    } catch (_) {
      return false;
    }
  }
}
