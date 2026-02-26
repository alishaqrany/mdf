import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/student_dashboard/presentation/pages/student_dashboard_page.dart';
import '../../features/admin_dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/course_content/presentation/pages/course_content_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Route name constants
abstract class AppRoutes {
  static const login = 'login';
  static const studentDashboard = 'student-dashboard';
  static const adminDashboard = 'admin-dashboard';
  static const courses = 'courses';
  static const courseContent = 'course-content';
  static const profile = 'profile';
  static const settings = 'settings';
}

/// GoRouter configuration with role-based guards
class AppRouter {
  final AuthBloc _authBloc;

  AppRouter(this._authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final authState = _authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      // Not authenticated → redirect to login
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // Authenticated → redirect away from login
      if (isAuthenticated && isLoginRoute) {
        if (authState.user.isAdmin) {
          return '/admin';
        }
        return '/student';
      }

      return null;
    },
    routes: [
      // ─── Login ───
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // ─── Student Shell ───
      ShellRoute(
        builder: (context, state, child) => _StudentShell(child: child),
        routes: [
          GoRoute(
            path: '/student',
            name: AppRoutes.studentDashboard,
            builder: (context, state) => const StudentDashboardPage(),
          ),
          GoRoute(
            path: '/student/courses',
            name: AppRoutes.courses,
            builder: (context, state) => const CoursesPage(),
          ),
          GoRoute(
            path: '/student/course/:courseId',
            name: AppRoutes.courseContent,
            builder: (context, state) {
              final courseId =
                  int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
              final courseTitle = state.uri.queryParameters['title'] ?? '';
              return CourseContentPage(
                courseId: courseId,
                courseTitle: courseTitle,
              );
            },
          ),
          GoRoute(
            path: '/student/profile',
            name: '${AppRoutes.profile}-student',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // ─── Admin Shell ───
      ShellRoute(
        builder: (context, state, child) => _AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin',
            name: AppRoutes.adminDashboard,
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/courses',
            name: 'admin-courses',
            builder: (context, state) => const CoursesPage(),
          ),
          GoRoute(
            path: '/admin/profile',
            name: '${AppRoutes.profile}-admin',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
}

// ─── Student Bottom Navigation Shell ───
class _StudentShell extends StatefulWidget {
  final Widget child;

  const _StudentShell({required this.child});

  @override
  State<_StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<_StudentShell> {
  int _currentIndex = 0;

  static final _tabs = ['/student', '/student/courses', '/student/profile'];

  @override
  Widget build(BuildContext context) {
    // Sync tab index with current route
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/student/courses')) {
      _currentIndex = 1;
    } else if (location.startsWith('/student/profile')) {
      _currentIndex = 2;
    } else {
      _currentIndex = 0;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index != _currentIndex) {
            context.go(_tabs[index]);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── Admin Bottom Navigation Shell ───
class _AdminShell extends StatefulWidget {
  final Widget child;

  const _AdminShell({required this.child});

  @override
  State<_AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<_AdminShell> {
  int _currentIndex = 0;

  static final _tabs = ['/admin', '/admin/courses', '/admin/profile'];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/courses')) {
      _currentIndex = 1;
    } else if (location.startsWith('/admin/profile')) {
      _currentIndex = 2;
    } else {
      _currentIndex = 0;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index != _currentIndex) {
            context.go(_tabs[index]);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: const Icon(Icons.admin_panel_settings_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ─── GoRouter Refresh Stream Helper ───
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
