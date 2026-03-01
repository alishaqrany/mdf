import 'package:flutter/material.dart';

/// Responsive layout breakpoints and helpers.
class ResponsiveLayout {
  ResponsiveLayout._();

  // ─── Breakpoints ───
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  // > 1024 → Desktop

  /// True if the screen is a phone (< 600dp).
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMaxWidth;

  /// True if the screen is a tablet (600 – 1024dp).
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileMaxWidth && w < tabletMaxWidth;
  }

  /// True if the screen is desktop-class (>= 1024dp).
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMaxWidth;

  /// True if wide enough for a side navigation (tablet or desktop).
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMaxWidth;

  /// Number of grid columns for the current width.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletMaxWidth) return 4;
    if (w >= mobileMaxWidth) return 3;
    return 2;
  }

  /// Recommended side panel width for master-detail layouts.
  static double sideWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= tabletMaxWidth) return 320;
    if (w >= mobileMaxWidth) return 280;
    return w;
  }

  /// Content area maximum width.
  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 800;
    return double.infinity;
  }
}

/// Builder that yields the right child based on screen width.
class ResponsiveBuilder extends StatelessWidget {
  /// Required — phone layout.
  final Widget mobile;

  /// Optional — tablet layout (defaults to [mobile]).
  final Widget? tablet;

  /// Optional — desktop layout (defaults to [tablet] ?? [mobile]).
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (ResponsiveLayout.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

/// Master-detail split view for tablets.
/// Shows [master] on the left and [detail] on the right when wide enough;
/// otherwise only [master] is shown and navigation is push-based.
class MasterDetailLayout extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final double masterWidth;

  const MasterDetailLayout({
    super.key,
    required this.master,
    this.detail,
    this.masterWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveLayout.isWide(context)) {
      return master;
    }

    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          child:
              detail ??
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'اختر عنصراً من القائمة',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}
