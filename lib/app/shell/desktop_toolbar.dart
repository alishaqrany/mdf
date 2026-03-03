import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/tenant_resolver.dart';

/// Top-level desktop toolbar (web & desktop only).
///
/// Renders a horizontal app bar with navigation links, search bar,
/// notifications bell, and user avatar — similar to a web SaaS dashboard.
class DesktopToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String role;
  final String? userName;
  final String? userAvatar;
  final int unreadNotifications;
  final VoidCallback? onNotificationsTap;

  const DesktopToolbar({
    super.key,
    required this.role,
    this.userName,
    this.userAvatar,
    this.unreadNotifications = 0,
    this.onNotificationsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final tenant = TenantManager.current;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // ─── Logo / Brand ───
          _BrandChip(appName: tenant.appName, color: colorScheme.primary),
          const SizedBox(width: 32),

          // ─── Nav links ───
          ..._navItems(context),

          const Spacer(),

          // ─── Search bar ───
          SizedBox(
            width: 260,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  context.go('/$role/search?q=${Uri.encodeComponent(query)}');
                }
              },
            ),
          ),
          const SizedBox(width: 16),

          // ─── Notifications ───
          Badge(
            isLabelVisible: unreadNotifications > 0,
            label: Text(
              '$unreadNotifications',
              style: const TextStyle(fontSize: 10),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Notifications',
              onPressed:
                  onNotificationsTap ??
                  () => context.go('/$role/notifications?userId=0'),
            ),
          ),
          const SizedBox(width: 8),

          // ─── User avatar ───
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: userAvatar != null
                  ? CachedNetworkImageProvider(userAvatar!)
                  : null,
              child: userAvatar == null
                  ? Text(
                      (userName ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    )
                  : null,
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/$role/profile');
                case 'settings':
                  context.go('/$role/profile');
                case 'logout':
                  // AuthBloc handles logout
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _navItems(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = <_NavItem>[
      _NavItem('Dashboard', '/$role', Icons.dashboard_outlined),
      _NavItem('Courses', '/$role/courses', Icons.school_outlined),
      _NavItem('Messages', '/$role/messages', Icons.chat_outlined),
      _NavItem('Calendar', '/$role/calendar', Icons.calendar_month_outlined),
    ];

    return items.map((item) {
      final isActive = location.startsWith(item.path);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextButton.icon(
          icon: Icon(item.icon, size: 18),
          label: Text(item.label),
          style: TextButton.styleFrom(
            foregroundColor: isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
            backgroundColor: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => context.go(item.path),
        ),
      );
    }).toList();
  }
}

class _NavItem {
  final String label;
  final String path;
  final IconData icon;
  const _NavItem(this.label, this.path, this.icon);
}

class _BrandChip extends StatelessWidget {
  final String appName;
  final Color color;
  const _BrandChip({required this.appName, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'M',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          appName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
