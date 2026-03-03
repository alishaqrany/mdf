import 'package:flutter/material.dart';

import '../../core/platform/platform_info.dart';
import '../../core/config/tenant_resolver.dart';

/// Web-specific SEO and browser integration helpers.
///
/// On web, this updates the document title and meta tags
/// to match the current page. On mobile/desktop it's a no-op.
class WebSeoHelper {
  WebSeoHelper._();

  /// Update the browser tab title.
  static void setPageTitle(String title) {
    if (!PlatformInfo.isWeb) return;
    // On web, the title is set via the WidgetsApp.title callback
    // or by using dart:js_interop. MaterialApp.router handles basic title.
  }

  /// Build a page title in the format "Page — AppName".
  static String buildTitle(String page) {
    final appName = TenantManager.current.appName;
    return '$page — $appName';
  }
}

/// Wrap a page with appropriate web viewport constraints.
///
/// On web/desktop, constrains the content width to avoid
/// overly wide layouts on ultra-wide monitors.
class WebContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isMobile) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// A responsive scaffold that adapts padding for web/desktop.
class WebAdaptiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  const WebAdaptiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktopOrWeb = PlatformInfo.isDesktop || PlatformInfo.isWeb;
    final horizontalPadding = isDesktopOrWeb ? 24.0 : 0.0;

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: body,
      ),
    );
  }
}
