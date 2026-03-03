import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shell/adaptive_shell.dart';
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
import '../../features/user_management/presentation/pages/user_list_page.dart';
import '../../features/user_management/presentation/pages/user_detail_page.dart';
import '../../features/user_management/presentation/pages/user_create_page.dart';
import '../../features/enrollment/presentation/pages/enrollment_page.dart';
import '../../features/video_meetings/presentation/pages/meeting_list_page.dart';
import '../../features/video_meetings/presentation/pages/meeting_detail_page.dart';
import '../../features/video_meetings/domain/entities/meeting.dart';
import '../../features/downloads/presentation/pages/downloads_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/ai/presentation/pages/ai_insights_page.dart';
import '../../features/ai/presentation/pages/ai_chat_page.dart';
import '../../features/social/presentation/pages/study_groups_page.dart';
import '../../features/social/presentation/pages/group_detail_page.dart';
import '../../features/social/presentation/pages/study_notes_page.dart';
import '../../features/social/presentation/pages/peer_review_page.dart';
import '../../features/social/presentation/pages/collaborative_session_page.dart';
import '../../features/gamification/presentation/pages/gamification_dashboard_page.dart';
import '../../features/gamification/presentation/pages/leaderboard_page.dart';
import '../../features/gamification/presentation/pages/badges_page.dart';
import '../../features/gamification/presentation/pages/challenges_page.dart';
import '../../features/course_visibility/presentation/pages/course_visibility_page.dart';
import '../../features/cohorts/presentation/pages/cohorts_page.dart';
import '../../features/cohorts/presentation/pages/cohort_detail_page.dart';

/// Route name constants
abstract class AppRoutes {
  static const splash = 'splash';
  static const onboarding = 'onboarding';
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
  static const userList = 'user-list';
  static const userDetail = 'user-detail';
  static const userCreate = 'user-create';
  static const enrollment = 'enrollment';
  static const meetingList = 'meeting-list';
  static const meetingDetail = 'meeting-detail';
  static const downloads = 'downloads';
  static const aiInsights = 'ai-insights';
  static const aiChat = 'ai-chat';
  static const studyGroups = 'study-groups';
  static const groupDetail = 'group-detail';
  static const groupNotes = 'group-notes';
  static const groupSessions = 'group-sessions';
  static const studyNotes = 'study-notes';
  static const peerReviews = 'peer-reviews';
  static const gamificationDashboard = 'gamification';
  static const leaderboard = 'leaderboard';
  static const badges = 'badges';
  static const challenges = 'challenges';
  static const courseVisibility = 'course-visibility';
  static const cohorts = 'cohorts';
  static const cohortDetail = 'cohort-detail';
}

/// GoRouter configuration with role-based guards
class AppRouter {
  final AuthBloc _authBloc;

  AppRouter(this._authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: (context, state) {
      final authState = _authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final loc = state.matchedLocation;

      // Allow splash & onboarding without auth
      if (loc == '/splash' || loc == '/onboarding') return null;

      final isLoginRoute = loc == '/login';

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
      // ─── Splash ───
      GoRoute(
        path: '/splash',
        name: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),

      // ─── Onboarding ───
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),

      // ─── Login ───
      GoRoute(
        path: '/login',
        name: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),

      // ─── Student Shell ───
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(role: 'student', child: child),
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
          GoRoute(
            path: '/student/downloads',
            name: '${AppRoutes.downloads}-student',
            builder: (context, state) => const DownloadsPage(),
          ),
          GoRoute(
            path: '/student/ai-insights',
            name: '${AppRoutes.aiInsights}-student',
            builder: (context, state) => const AiInsightsPage(),
          ),
          GoRoute(
            path: '/student/ai-chat',
            name: '${AppRoutes.aiChat}-student',
            builder: (context, state) => const AiChatPage(),
          ),

          // ─── Social ───
          GoRoute(
            path: '/student/study-groups',
            name: '${AppRoutes.studyGroups}-student',
            builder: (context, state) {
              final courseId = int.tryParse(
                state.uri.queryParameters['courseId'] ?? '',
              );
              return StudyGroupsPage(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/student/group/:groupId',
            name: '${AppRoutes.groupDetail}-student',
            builder: (context, state) {
              final groupId =
                  int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
              return GroupDetailPage(groupId: groupId);
            },
          ),
          GoRoute(
            path: '/student/group/:groupId/notes',
            name: '${AppRoutes.groupNotes}-student',
            builder: (context, state) {
              final groupId =
                  int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
              return StudyNotesPage(groupId: groupId);
            },
          ),
          GoRoute(
            path: '/student/group/:groupId/sessions',
            name: '${AppRoutes.groupSessions}-student',
            builder: (context, state) {
              final groupId =
                  int.tryParse(state.pathParameters['groupId'] ?? '') ?? 0;
              final groupName = state.uri.queryParameters['name'] ?? '';
              return CollaborativeSessionPage(
                groupId: groupId,
                groupName: groupName,
              );
            },
          ),
          GoRoute(
            path: '/student/study-notes/:courseId',
            name: '${AppRoutes.studyNotes}-student',
            builder: (context, state) {
              final courseId =
                  int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
              return StudyNotesPage(courseId: courseId);
            },
          ),
          GoRoute(
            path: '/student/peer-reviews',
            name: '${AppRoutes.peerReviews}-student',
            builder: (context, state) => const PeerReviewPage(),
          ),

          // ─── Gamification ───
          GoRoute(
            path: '/student/gamification',
            name: '${AppRoutes.gamificationDashboard}-student',
            builder: (context, state) => const GamificationDashboardPage(),
          ),
          GoRoute(
            path: '/student/leaderboard',
            name: '${AppRoutes.leaderboard}-student',
            builder: (context, state) => const LeaderboardPage(),
          ),
          GoRoute(
            path: '/student/badges',
            name: '${AppRoutes.badges}-student',
            builder: (context, state) => const BadgesPage(),
          ),
          GoRoute(
            path: '/student/challenges',
            name: '${AppRoutes.challenges}-student',
            builder: (context, state) => const ChallengesPage(),
          ),
        ],
      ),

      // ─── Admin Shell ───
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveShell(role: 'admin', child: child),
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
          GoRoute(
            path: '/admin/downloads',
            name: '${AppRoutes.downloads}-admin',
            builder: (context, state) => const DownloadsPage(),
          ),
          GoRoute(
            path: '/admin/ai-insights',
            name: '${AppRoutes.aiInsights}-admin',
            builder: (context, state) => const AiInsightsPage(),
          ),
          GoRoute(
            path: '/admin/ai-chat',
            name: '${AppRoutes.aiChat}-admin',
            builder: (context, state) => const AiChatPage(),
          ),
          // ─── User Management Routes ───
          GoRoute(
            path: '/admin/users',
            name: AppRoutes.userList,
            builder: (context, state) => const UserListPage(),
          ),
          GoRoute(
            path: '/admin/users/create',
            name: AppRoutes.userCreate,
            builder: (context, state) => const UserCreatePage(),
          ),
          GoRoute(
            path: '/admin/users/:userId',
            name: AppRoutes.userDetail,
            builder: (context, state) {
              final userId =
                  int.tryParse(state.pathParameters['userId'] ?? '') ?? 0;
              return UserDetailPage(userId: userId);
            },
          ),
          // ─── Enrollment Route ───
          GoRoute(
            path: '/admin/enrollment',
            name: AppRoutes.enrollment,
            builder: (context, state) {
              final courseId = int.tryParse(
                state.uri.queryParameters['courseId'] ?? '',
              );
              return EnrollmentPage(preselectedCourseId: courseId);
            },
          ),
          // ─── Course Visibility Route ───
          GoRoute(
            path: '/admin/course-visibility',
            name: AppRoutes.courseVisibility,
            builder: (context, state) => const CourseVisibilityPage(),
          ),
          // ─── Cohort Routes ───
          GoRoute(
            path: '/admin/cohorts',
            name: AppRoutes.cohorts,
            builder: (context, state) => const CohortsPage(),
          ),
          GoRoute(
            path: '/admin/cohorts/:cohortId',
            name: AppRoutes.cohortDetail,
            builder: (context, state) {
              final cohortId =
                  int.tryParse(state.pathParameters['cohortId'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final cohortName = extra?['cohortName'] as String? ?? '';
              return CohortDetailPage(
                cohortId: cohortId,
                cohortName: cohortName,
              );
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

  // ─── Meetings ───
  GoRoute(
    path: '/meeting/list/:courseId',
    name: AppRoutes.meetingList,
    builder: (context, state) {
      final courseId =
          int.tryParse(state.pathParameters['courseId'] ?? '') ?? 0;
      final courseTitle = state.uri.queryParameters['title'] ?? '';
      return MeetingListPage(courseId: courseId, courseTitle: courseTitle);
    },
  ),
  GoRoute(
    path: '/meeting/:meetingId',
    name: AppRoutes.meetingDetail,
    builder: (context, state) {
      final meeting = _extra<Meeting>(state, 'meeting');
      return MeetingDetailPage(meeting: meeting!);
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
