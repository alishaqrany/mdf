import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/notifications/presentation/bloc/notification_bloc.dart';
import '../di/injection.dart';

/// Shared adaptive shell that renders:
///  - BottomNavigationBar on phones
///  - NavigationRail + optional extended drawer on tablets/desktop
///
/// Parameterised by [role] so both student and admin can reuse it.
class AdaptiveShell extends StatefulWidget {
  final Widget child;
  final String role; // 'student' | 'admin'

  const AdaptiveShell({super.key, required this.child, required this.role});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  int _currentIndex = 0;
  late final NotificationBadgeCubit _badgeCubit;
  int? _userId;

  List<String> get _tabs => [
    '/${widget.role}',
    '/${widget.role}/courses',
    '/${widget.role}/messages',
    '/${widget.role}/calendar',
    '/${widget.role}/profile',
  ];

  @override
  void initState() {
    super.initState();
    _badgeCubit = NotificationBadgeCubit(repository: sl());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && _userId == null) {
      _userId = authState.user.id;
      _badgeCubit.loadUnreadCount(_userId!);
    }
  }

  @override
  void dispose() {
    _badgeCubit.close();
    super.dispose();
  }

  void _syncIndex(String location) {
    final role = widget.role;
    if (location.startsWith('/$role/courses')) {
      _currentIndex = 1;
    } else if (location.startsWith('/$role/messages')) {
      _currentIndex = 2;
    } else if (location.startsWith('/$role/calendar')) {
      _currentIndex = 3;
    } else if (location.startsWith('/$role/profile')) {
      _currentIndex = 4;
    } else {
      _currentIndex = 0;
    }
  }

  // ─── Destination metadata ───
  bool get _isAdmin => widget.role == 'admin';

  List<NavigationDestination> get _bottomDestinations => [
    NavigationDestination(
      icon: Icon(
        _isAdmin
            ? Icons.admin_panel_settings_outlined
            : Icons.dashboard_outlined,
      ),
      selectedIcon: Icon(
        _isAdmin ? Icons.admin_panel_settings_rounded : Icons.dashboard_rounded,
      ),
      label: 'Dashboard',
    ),
    const NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school_rounded),
      label: 'Courses',
    ),
    const NavigationDestination(
      icon: Icon(Icons.chat_outlined),
      selectedIcon: Icon(Icons.chat_rounded),
      label: 'Messages',
    ),
    const NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Calendar',
    ),
    const NavigationDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  List<NavigationRailDestination> get _railDestinations => [
    NavigationRailDestination(
      icon: Icon(
        _isAdmin
            ? Icons.admin_panel_settings_outlined
            : Icons.dashboard_outlined,
      ),
      selectedIcon: Icon(
        _isAdmin ? Icons.admin_panel_settings_rounded : Icons.dashboard_rounded,
      ),
      label: const Text('Dashboard'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school_rounded),
      label: Text('Courses'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.chat_outlined),
      selectedIcon: Icon(Icons.chat_rounded),
      label: Text('Messages'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: Text('Calendar'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.person_outlined),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    _syncIndex(location);

    final isWide = ResponsiveLayout.isWide(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // ─── Wide screens: NavigationRail ───
    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: isDesktop,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                if (index != _currentIndex) context.go(_tabs[index]);
              },
              labelType: isDesktop
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.selected,
              leading: _buildRailLeading(context, isDesktop),
              trailing: _buildRailTrailing(context),
              destinations: _railDestinations,
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    // ─── Phones: BottomNavigationBar ───
    return Scaffold(
      body: widget.child,
      floatingActionButton: _buildNotificationFab(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index != _currentIndex) context.go(_tabs[index]);
        },
        destinations: _bottomDestinations,
      ),
    );
  }

  // ─── Rail leading (logo + notification) ───
  Widget _buildRailLeading(BuildContext context, bool extended) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          if (extended)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'MDF',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 2,
                ),
              ),
            ),
          BlocBuilder<NotificationBadgeCubit, int>(
            bloc: _badgeCubit,
            builder: (context, count) {
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () {
                  context.go(
                    '/${widget.role}/notifications?userId=${_userId ?? 0}',
                  );
                },
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count', style: const TextStyle(fontSize: 10)),
                  child: const Icon(Icons.notifications_outlined),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Rail trailing (extra items for admin) ───
  Widget? _buildRailTrailing(BuildContext context) {
    if (!_isAdmin) return null;
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Users',
                icon: const Icon(Icons.people_outlined),
                onPressed: () => context.go('/admin/users'),
              ),
              const SizedBox(height: 8),
              IconButton(
                tooltip: 'Enrollment',
                icon: const Icon(Icons.how_to_reg_outlined),
                onPressed: () => context.go('/admin/enrollment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Notification FAB (mobile only) ───
  Widget? _buildNotificationFab(BuildContext context) {
    if (_currentIndex != 0) return null;
    return BlocBuilder<NotificationBadgeCubit, int>(
      bloc: _badgeCubit,
      builder: (context, unreadCount) {
        return FloatingActionButton.small(
          heroTag: '${widget.role}_notifications',
          onPressed: () {
            context.go('/${widget.role}/notifications?userId=${_userId ?? 0}');
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && _userId != null) {
                _badgeCubit.loadUnreadCount(_userId!);
              }
            });
          },
          child: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text('$unreadCount', style: const TextStyle(fontSize: 10)),
            child: const Icon(Icons.notifications_outlined),
          ),
        );
      },
    );
  }
}
