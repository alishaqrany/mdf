import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/student_dashboard/presentation/pages/student_dashboard_page.dart';
import '../../features/admin_dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/courses/presentation/pages/courses_page.dart';
import '../../features/course_detail/presentation/pages/course_detail_page.dart';
import '../../features/content_viewer/presentation/pages/video_player_page.dart';
import '../../features/content_viewer/presentation/pages/pdf_viewer_page.dart';
import '../../features/content_viewer/presentation/pages/html_content_page.dart';
import '../../features/content_viewer/presentation/pages/scorm_player_page.dart';
import '../../features/content_viewer/presentation/pages/h5p_player_page.dart';
import '../../features/course_content/domain/entities/course_content.dart';
import '../../features/profile/presentation/pages/profile_page.dart';

/// Route name constants
abstract class AppRoutes {
  static const login = 'login';
  static const studentDashboard = 'student-dashboard';
  static const adminDashboard = 'admin-dashboard';
  static const courses = 'courses';
  static const courseContent = 'course-content';
  static const courseDetail = 'course-detail';
  static const videoPlayer = 'video-player';
  static const pdfViewer = 'pdf-viewer';
  static const htmlContent = 'html-content';
  static const scormPlayer = 'scorm-player';
  static const h5pPlayer = 'h5p-player';
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
              final imageUrl = state.uri.queryParameters['image'];
              return CourseDetailPage(
                courseId: courseId,
                courseTitle: courseTitle,
                imageUrl: imageUrl,
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
            path: '/admin/course/:courseId',
            name: 'admin-course-detail',
            builder: (context, state) {
              final courseId =
                  int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
              final courseTitle = state.uri.queryParameters['title'] ?? '';
              final imageUrl = state.uri.queryParameters['image'];
              return CourseDetailPage(
                courseId: courseId,
                courseTitle: courseTitle,
                imageUrl: imageUrl,
              );
            },
          ),
          GoRoute(
            path: '/admin/profile',
            name: '${AppRoutes.profile}-admin',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // ─── Content Viewer Routes (shared) ───
      ..._contentViewerRoutes,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.matchedLocation}')),
    ),
  );
}

/// Extract typed extra data safely.
T? _extra<T>(GoRouterState state, String key) {
  final extra = state.extra;
  if (extra is Map<String, dynamic>) {
    return extra[key] as T?;
  }
  return null;
}

/// Content viewer routes — accessible from any shell.
List<RouteBase> get _contentViewerRoutes => [
  GoRoute(
    path: '/content/video',
    name: AppRoutes.videoPlayer,
    builder: (context, state) {
      return VideoPlayerPage(
        title: _extra<String>(state, 'title') ?? '',
        videoUrl: _extra<String>(state, 'videoUrl') ?? '',
      );
    },
  ),
  GoRoute(
    path: '/content/pdf',
    name: AppRoutes.pdfViewer,
    builder: (context, state) {
      return PdfViewerPage(
        title: _extra<String>(state, 'title') ?? '',
        pdfUrl: _extra<String>(state, 'pdfUrl') ?? '',
      );
    },
  ),
  GoRoute(
    path: '/content/html',
    name: AppRoutes.htmlContent,
    builder: (context, state) {
      return HtmlContentPage(
        title: _extra<String>(state, 'title') ?? '',
        url: _extra<String>(state, 'url'),
        description: _extra<String>(state, 'description'),
        contents: _extra<List<ModuleContent>>(state, 'contents'),
      );
    },
  ),
  GoRoute(
    path: '/content/scorm',
    name: AppRoutes.scormPlayer,
    builder: (context, state) {
      return ScormPlayerPage(
        title: _extra<String>(state, 'title') ?? '',
        url: _extra<String>(state, 'url'),
        instance: _extra<int>(state, 'instance'),
        courseId: _extra<int>(state, 'courseId'),
      );
    },
  ),
  GoRoute(
    path: '/content/h5p',
    name: AppRoutes.h5pPlayer,
    builder: (context, state) {
      return H5pPlayerPage(
        title: _extra<String>(state, 'title') ?? '',
        url: _extra<String>(state, 'url'),
        instance: _extra<int>(state, 'instance'),
      );
    },
  ),
];

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
