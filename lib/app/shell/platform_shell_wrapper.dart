import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/platform_info.dart';
import '../../../core/platform/platform_window.dart';
import '../../../core/widgets/responsive_layout.dart';

/// Wraps the router's shell with platform-specific enhancements:
///
/// - **Web/Desktop**: adds a top [DesktopToolbar] + keyboard shortcuts.
/// - **Mobile**: returns child as-is (AdaptiveShell handles bottom nav).
class PlatformShellWrapper extends StatelessWidget {
  final Widget child;
  final String role;

  const PlatformShellWrapper({
    super.key,
    required this.child,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    // On phones → no toolbar: the AdaptiveShell already provides nav.
    if (!ResponsiveLayout.isDesktop(context) && !PlatformInfo.isWeb) {
      return child;
    }

    // Desktop / web → add keyboard shortcuts + toolbar.
    return Shortcuts(
      shortcuts: PlatformWindow.desktopShortcuts,
      child: Actions(
        actions: <Type, Action<Intent>>{
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (_) => context.go('/$role/search'),
          ),
          NewMessageIntent: CallbackAction<NewMessageIntent>(
            onInvoke: (_) => context.go('/$role/messages'),
          ),
          DashboardIntent: CallbackAction<DashboardIntent>(
            onInvoke: (_) => context.go('/$role'),
          ),
          RefreshIntent: CallbackAction<RefreshIntent>(
            onInvoke: (_) {
              // Could trigger a rebuild / BLoC refresh here
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
