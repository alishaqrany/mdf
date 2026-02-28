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
import '../../features/quizzes/presentation/pages/quiz_list_page.dart';
import '../../features/quizzes/presentation/pages/quiz_info_page.dart';
import '../../features/quizzes/presentation/pages/quiz_attempt_page.dart';
import '../../features/quizzes/presentation/pages/quiz_review_page.dart';
import '../../features/assignments/presentation/pages/assignment_list_page.dart';
import '../../features/assignments/presentation/pages/assignment_detail_page.dart';
import '../../features/grades/presentation/pages/grades_page.dart';
import '../../features/messaging/presentation/pages/conversations_page.dart';
import '../../features/messaging/presentation/pages/chat_page.dart';
import '../../features/forums/presentation/pages/forum_list_page.dart';
import '../../features/forums/presentation/pages/discussion_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/search/presentation/pages/search_page.dart';

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
  static const quizList = 'quiz-list';
  static const quizInfo = 'quiz-info';
  static const quizAttempt = 'quiz-attempt';
  static const quizReview = 'quiz-review';
  static const assignmentList = 'assignment-list';
  static const assignmentDetail = 'assignment-detail';
  static const grades = 'grades';
  static const courseGrades = 'course-grades';
  static const conversations = 'conversations';
  static const chat = 'chat';
  static const forumList = 'forum-list';
  static const forumDiscussions = 'forum-discussions';
  static const forumPosts = 'forum-posts';
  static const notifications = 'notifications';
  static const calendar = 'calendar';
  static const search = 'search';
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
          GoRoute(
            path: '/student/messages',
            name: '${AppRoutes.conversations}-student',
            builder: (context, state) {
              final userId =
                  int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
              return ConversationsPage(userId: userId);
            },
          ),
          GoRoute(
            path: '/student/notifications',
            name: '${AppRoutes.notifications}-student',
            builder: (context, state) {
              final userId =
                  int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
              return NotificationsPage(userId: userId);
            },
          ),
          GoRoute(
            path: '/student/calendar',
            name: '${AppRoutes.calendar}-student',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/student/search',
            name: '${AppRoutes.search}-student',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/student/grades',
            name: '${AppRoutes.grades}-student',
            builder: (context, state) {
              final userId =
                  int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
              return GradesPage(userId: userId);
            },
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
          GoRoute(
            path: '/admin/messages',
            name: '${AppRoutes.conversations}-admin',
            builder: (context, state) {
              final userId =
                  int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
              return ConversationsPage(userId: userId);
            },
          ),
          GoRoute(
            path: '/admin/notifications',
            name: '${AppRoutes.notifications}-admin',
            builder: (context, state) {
              final userId =
                  int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
              return NotificationsPage(userId: userId);
            },
          ),
          GoRoute(
            path: '/admin/calendar',
            name: '${AppRoutes.calendar}-admin',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/admin/search',
            name: '${AppRoutes.search}-admin',
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: '/admin/grades',
            name: '${AppRoutes.grades}-admin',
            builder: (context, state) {
              final userId =
                  int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
              return GradesPage(userId: userId);
            },
          ),
        ],
      ),

      // ─── Content Viewer Routes (shared) ───
      ..._contentViewerRoutes,

      // ─── Feature Routes (shared) ───
      ..._featureRoutes,
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

/// Feature routes — accessible from any shell.
List<RouteBase> get _featureRoutes => [
  // ─── Quizzes ───
  GoRoute(
    path: '/quiz/list/:courseId',
    name: AppRoutes.quizList,
    builder: (context, state) {
      final courseId =
          int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
      final courseTitle = state.uri.queryParameters['title'] ?? '';
      return QuizListPage(courseId: courseId, courseTitle: courseTitle);
    },
  ),
  GoRoute(
    path: '/quiz/info',
    name: AppRoutes.quizInfo,
    builder: (context, state) {
      return QuizInfoPage(quiz: _extra(state, 'quiz'));
    },
  ),
  GoRoute(
    path: '/quiz/attempt/:attemptId',
    name: AppRoutes.quizAttempt,
    builder: (context, state) {
      final attemptId =
          int.tryParse(state.pathParameters['attemptId'] ?? '') ?? 0;
      final quizId =
          int.tryParse(state.uri.queryParameters['quizId'] ?? '') ?? 0;
      final timeLimit = int.tryParse(
        state.uri.queryParameters['timeLimit'] ?? '',
      );
      return QuizAttemptPage(
        attemptId: attemptId,
        quizId: quizId,
        timeLimit: timeLimit,
      );
    },
  ),
  GoRoute(
    path: '/quiz/review/:attemptId',
    name: AppRoutes.quizReview,
    builder: (context, state) {
      final attemptId =
          int.tryParse(state.pathParameters['attemptId'] ?? '') ?? 0;
      return QuizReviewPage(attemptId: attemptId);
    },
  ),

  // ─── Assignments ───
  GoRoute(
    path: '/assignment/list/:courseId',
    name: AppRoutes.assignmentList,
    builder: (context, state) {
      final courseId =
          int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
      return AssignmentListPage(courseId: courseId);
    },
  ),
  GoRoute(
    path: '/assignment/detail/:assignmentId',
    name: AppRoutes.assignmentDetail,
    builder: (context, state) {
      return AssignmentDetailPage(assignment: _extra(state, 'assignment'));
    },
  ),

  // ─── Grades (for specific course) ───
  GoRoute(
    path: '/grades/:courseId',
    name: AppRoutes.courseGrades,
    builder: (context, state) {
      final courseId =
          int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
      final userId =
          int.tryParse(state.uri.queryParameters['userId'] ?? '') ?? 0;
      return GradesPage(courseId: courseId, userId: userId);
    },
  ),

  // ─── Messaging ───
  GoRoute(
    path: '/chat/:conversationId',
    name: AppRoutes.chat,
    builder: (context, state) {
      final conversationId =
          int.tryParse(state.pathParameters['conversationId'] ?? '') ?? 0;
      final userId = _extra<int>(state, 'userId') ?? 0;
      final toUserId = _extra<int>(state, 'toUserId') ?? 0;
      return ChatPage(
        conversationId: conversationId,
        userId: userId,
        toUserId: toUserId,
        title: _extra<String>(state, 'title') ?? '',
      );
    },
  ),

  // ─── Forums ───
  GoRoute(
    path: '/forum/list/:courseId',
    name: AppRoutes.forumList,
    builder: (context, state) {
      final courseId =
          int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
      return ForumListPage(courseId: courseId);
    },
  ),
  GoRoute(
    path: '/forum/discussions/:forumId',
    name: AppRoutes.forumDiscussions,
    builder: (context, state) {
      final forumId = int.tryParse(state.pathParameters['forumId'] ?? '') ?? 0;
      final forumName = state.uri.queryParameters['name'] ?? '';
      return DiscussionsPage(forumId: forumId, forumName: forumName);
    },
  ),
  GoRoute(
    path: '/forum/posts/:discussionId',
    name: AppRoutes.forumPosts,
    builder: (context, state) {
      final discussionId =
          int.tryParse(state.pathParameters['discussionId'] ?? '') ?? 0;
      final discussionName = state.uri.queryParameters['name'] ?? '';
      return PostsPage(
        discussionId: discussionId,
        discussionName: discussionName,
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

  static final _tabs = [
    '/student',
    '/student/courses',
    '/student/messages',
    '/student/calendar',
    '/student/profile',
  ];

  @override
  Widget build(BuildContext context) {
    // Sync tab index with current route
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/student/courses')) {
      _currentIndex = 1;
    } else if (location.startsWith('/student/messages')) {
      _currentIndex = 2;
    } else if (location.startsWith('/student/calendar')) {
      _currentIndex = 3;
    } else if (location.startsWith('/student/profile')) {
      _currentIndex = 4;
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
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
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

  static final _tabs = [
    '/admin',
    '/admin/courses',
    '/admin/messages',
    '/admin/calendar',
    '/admin/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/admin/courses')) {
      _currentIndex = 1;
    } else if (location.startsWith('/admin/messages')) {
      _currentIndex = 2;
    } else if (location.startsWith('/admin/calendar')) {
      _currentIndex = 3;
    } else if (location.startsWith('/admin/profile')) {
      _currentIndex = 4;
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
            icon: const Icon(Icons.chat_outlined),
            selectedIcon: const Icon(Icons.chat_rounded),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: 'Calendar',
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
