import 'package:flutter/material.dart';

import '../../core/config/tenant_resolver.dart';
import '../../core/platform/platform_info.dart';

/// A footer that appears on web/desktop builds.
/// Hidden on mobile to save space.
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isMobile) return const SizedBox.shrink();

    final tenant = TenantManager.current;
    final year = DateTime.now().year;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Text(
            '© $year ${tenant.appName}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Spacer(),
          if (tenant.termsUrl != null)
            TextButton(
              onPressed: () {
                // Open terms URL
              },
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              child: const Text('Terms'),
            ),
          if (tenant.privacyUrl != null)
            TextButton(
              onPressed: () {
                // Open privacy URL
              },
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              child: const Text('Privacy'),
            ),
          if (tenant.supportEmail != null)
            TextButton(
              onPressed: () {
                // Open email
              },
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              child: const Text('Support'),
            ),
        ],
      ),
    );
  }
}
