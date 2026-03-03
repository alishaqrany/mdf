import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'platform_info.dart';

/// Platform-aware content viewer helpers.
///
/// On mobile the caller can use WebView or native PDF viewer.
/// On web / desktop these fall back to URL-based launching or
/// an embedded `HtmlElementView` (web) / `iframe`-style widget.
class PlatformContentViewer {
  PlatformContentViewer._();

  /// Open a URL externally (all platforms).
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Open a URL inside the app where possible, external otherwise.
  static Future<bool> openUrlInApp(String url) async {
    final uri = Uri.parse(url);
    if (PlatformInfo.supportsWebView) {
      // Mobile: will be handled by the caller's WebView page
      return true;
    }
    // Web / Desktop: open in a new tab / browser
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    return false;
  }

  /// Whether the current platform can show inline WebView content.
  static bool get canShowInlineWebView => PlatformInfo.supportsWebView;

  /// Build a platform–appropriate web content widget.
  ///
  /// On mobile returns null (caller should push WebView page).
  /// On web returns an HTML iframe-style widget.
  static Widget? buildWebContent(String url, {double? height}) {
    if (PlatformInfo.isWeb) {
      // On web — use HtmlElementView via url_launcher or simple link
      return SizedBox(
        height: height ?? 500,
        child: Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open in new tab'),
            onPressed: () => openUrl(url),
          ),
        ),
      );
    }
    return null; // Caller uses native WebView
  }
}
