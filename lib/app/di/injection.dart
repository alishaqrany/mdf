import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/moodle_api_client.dart';
import '../../core/api/graphql_client.dart';
import '../../core/network/network_info.dart';
import '../../core/platform/platform_info.dart';
import '../../core/platform/platform_storage.dart';
import '../../core/config/tenant_resolver.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/courses/data/datasources/courses_remote_datasource.dart';
import '../../features/courses/data/repositories/courses_repository_impl.dart';
import '../../features/courses/domain/repositories/courses_repository.dart';
import '../../features/courses/domain/usecases/get_enrolled_courses_usecase.dart';
import '../../features/courses/domain/usecases/get_course_contents_usecase.dart';
import '../../features/courses/domain/usecases/search_courses_usecase.dart';
import '../../features/courses/presentation/bloc/courses_bloc.dart';
import '../../features/course_content/data/datasources/course_content_remote_datasource.dart';
import '../../features/course_content/data/repositories/course_content_repository_impl.dart';
import '../../features/course_content/domain/repositories/course_content_repository.dart';
import '../../features/course_content/presentation/bloc/course_content_bloc.dart';
import '../../features/course_detail/data/datasources/course_detail_remote_datasource.dart';
import '../../features/student_dashboard/presentation/bloc/student_dashboard_bloc.dart';
import '../../features/admin_dashboard/presentation/bloc/admin_dashboard_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

// ─── Quizzes ───
import '../../features/quizzes/data/datasources/quiz_remote_datasource.dart';
import '../../features/quizzes/data/repositories/quiz_repository_impl.dart';
import '../../features/quizzes/domain/repositories/quiz_repository.dart';
import '../../features/quizzes/presentation/bloc/quiz_bloc.dart';

// ─── Assignments ───
import '../../features/assignments/data/datasources/assignment_remote_datasource.dart';
import '../../features/assignments/data/repositories/assignment_repository_impl.dart';
import '../../features/assignments/domain/repositories/assignment_repository.dart';
import '../../features/assignments/presentation/bloc/assignment_bloc.dart';

// ─── Grades ───
import '../../features/grades/data/datasources/grade_remote_datasource.dart';
import '../../features/grades/data/repositories/grade_repository_impl.dart';
import '../../features/grades/domain/repositories/grade_repository.dart';
import '../../features/grades/presentation/bloc/grades_bloc.dart';

// ─── Messaging ───
import '../../features/messaging/data/datasources/messaging_remote_datasource.dart';
import '../../features/messaging/data/repositories/messaging_repository_impl.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';

// ─── Forums ───
import '../../features/forums/data/datasources/forum_remote_datasource.dart';
import '../../features/forums/data/repositories/forum_repository_impl.dart';
import '../../features/forums/domain/repositories/forum_repository.dart';
import '../../features/forums/presentation/bloc/forum_bloc.dart';

// ─── Notifications ───
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';

// ─── Calendar ───
import '../../features/calendar/data/datasources/calendar_remote_datasource.dart';
import '../../features/calendar/data/repositories/calendar_repository_impl.dart';
import '../../features/calendar/domain/repositories/calendar_repository.dart';
import '../../features/calendar/presentation/bloc/calendar_bloc.dart';

// ─── User Management ───
import '../../features/user_management/data/datasources/user_management_remote_datasource.dart';
import '../../features/user_management/data/repositories/user_management_repository_impl.dart';
import '../../features/user_management/domain/repositories/user_management_repository.dart';
import '../../features/user_management/presentation/bloc/user_management_bloc.dart';

// ─── Enrollment ───
import '../../features/enrollment/data/datasources/enrollment_remote_datasource.dart';
import '../../features/enrollment/data/repositories/enrollment_repository_impl.dart';
import '../../features/enrollment/domain/repositories/enrollment_repository.dart';
import '../../features/enrollment/presentation/bloc/enrollment_bloc.dart';

// ─── Video Meetings ───
import '../../features/video_meetings/data/datasources/meeting_remote_datasource.dart';
import '../../features/video_meetings/data/repositories/meeting_repository_impl.dart';
import '../../features/video_meetings/domain/repositories/meeting_repository.dart';
import '../../features/video_meetings/presentation/bloc/meeting_bloc.dart';

// ─── Search ───
import '../../features/search/data/datasources/search_remote_datasource.dart';
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';

// ─── Offline & Downloads ───
import '../../core/storage/download_manager.dart';
import '../../core/storage/offline_queue.dart';
import '../../core/network/connectivity_cubit.dart';
import '../../features/downloads/presentation/bloc/downloads_bloc.dart';

// ─── Theme ───
import '../../core/theme/theme_cubit.dart';

// ─── AI Features ───
import '../../features/ai/data/ai_engine.dart';
import '../../features/ai/data/datasources/ai_remote_datasource.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../features/ai/presentation/bloc/ai_insights_bloc.dart';
import '../../features/ai/presentation/bloc/ai_chat_bloc.dart';
import '../../features/ai/presentation/bloc/ai_admin_bloc.dart';

// ─── Social Features ───
import '../../features/social/data/datasources/social_remote_datasource.dart';
import '../../features/social/data/repositories/social_repository_impl.dart';
import '../../features/social/domain/repositories/social_repository.dart';
import '../../features/social/presentation/bloc/study_groups_bloc.dart';
import '../../features/social/presentation/bloc/study_notes_bloc.dart';
import '../../features/social/presentation/bloc/peer_review_bloc.dart';
import '../../features/social/presentation/bloc/collaborative_bloc.dart';

// ─── Gamification ───
import '../../features/gamification/data/datasources/gamification_remote_datasource.dart';
import '../../features/gamification/data/repositories/gamification_repository_impl.dart';
import '../../features/gamification/domain/repositories/gamification_repository.dart';
import '../../features/gamification/presentation/bloc/points_bloc.dart';
import '../../features/gamification/presentation/bloc/badges_bloc.dart';
import '../../features/gamification/presentation/bloc/leaderboard_bloc.dart';
import '../../features/gamification/presentation/bloc/challenges_bloc.dart';

// ─── Course Visibility ───
import '../../features/course_visibility/presentation/bloc/course_visibility_bloc.dart';
import '../../features/course_visibility/data/datasources/course_visibility_remote_datasource.dart';

// ─── Cohorts ───
import '../../features/cohorts/presentation/bloc/cohort_bloc.dart';

// ─── Course Create ───
import '../../features/courses/presentation/bloc/course_create_bloc.dart';

// ─── Course Management ───
import '../../features/course_management/data/datasources/course_management_remote_datasource.dart';
import '../../features/course_management/presentation/bloc/course_management_bloc.dart';

// ─── Notification Admin ───
import '../../features/notification_admin/data/datasources/notification_admin_remote_datasource.dart';
import '../../features/notification_admin/presentation/bloc/notification_admin_bloc.dart';

// ─── Content Protection ───
import '../../features/content_protection/data/datasources/content_protection_remote_datasource.dart';
import '../../features/content_protection/presentation/bloc/content_protection_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies.
Future<void> initDependencies() async {
  // ─── External ───
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Connectivity());

  // ─── Platform Storage (web-safe secure storage) ───
  sl.registerLazySingleton<PlatformStorage>(
    () => PlatformStorage(secureStorage: sl(), prefs: sl()),
  );

  // ─── Multi-Tenant ───
  sl.registerLazySingleton<TenantResolver>(() => TenantResolver(prefs: sl()));
  final tenantConfig = await sl<TenantResolver>().resolve();
  TenantManager.init(tenantConfig);

  // ─── Core ───
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<MoodleApiClient>(
    () => MoodleApiClient(secureStorage: sl()),
  );

  // ─── GraphQL API Gateway ───
  sl.registerLazySingleton<GraphQLClient>(() => GraphQLClient(storage: sl()));

  // ─── Auth Feature ───
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(secureStorage: sl(), sharedPreferences: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthUseCase: sl(),
      refreshTokenUseCase: sl(),
    ),
  );

  // ─── Courses Feature ───
  sl.registerLazySingleton<CourseVisibilityRemoteDataSource>(
    () => CourseVisibilityRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CoursesRemoteDataSource>(
    () => CoursesRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CoursesRepository>(
    () => CoursesRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      visibilityDataSource: sl<CourseVisibilityRemoteDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => GetEnrolledCoursesUseCase(sl()));
  sl.registerLazySingleton(() => GetCourseContentsUseCase(sl()));
  sl.registerLazySingleton(() => SearchCoursesUseCase(sl()));
  sl.registerFactory(
    () => CoursesBloc(getEnrolledCourses: sl(), searchCourses: sl()),
  );

  // ─── Course Content Feature ───
  sl.registerLazySingleton<CourseContentRemoteDataSource>(
    () => CourseContentRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CourseContentRepository>(
    () =>
        CourseContentRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => CourseContentBloc(repository: sl()));

  // ─── Course Detail Feature ───
  sl.registerLazySingleton<CourseDetailRemoteDataSource>(
    () => CourseDetailRemoteDataSourceImpl(apiClient: sl()),
  );

  // ─── Student Dashboard ───
  sl.registerFactory(
    () => StudentDashboardBloc(
      coursesRepository: sl(),
      authRepository: sl(),
      calendarRepository: sl(),
    ),
  );

  // ─── Admin Dashboard ───
  sl.registerFactory(() => AdminDashboardBloc(apiClient: sl()));

  // ─── Profile Feature ───
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => ProfileBloc(repository: sl()));

  // ─── Quizzes Feature ───
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => QuizBloc(repository: sl()));

  // ─── Assignments Feature ───
  sl.registerLazySingleton<AssignmentRemoteDataSource>(
    () => AssignmentRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AssignmentRepository>(
    () => AssignmentRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => AssignmentBloc(repository: sl()));

  // ─── Grades Feature ───
  sl.registerLazySingleton<GradeRemoteDataSource>(
    () => GradeRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<GradeRepository>(
    () => GradeRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => GradesBloc(repository: sl()));

  // ─── Messaging Feature ───
  sl.registerLazySingleton<MessagingRemoteDataSource>(
    () => MessagingRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<MessagingRepository>(
    () => MessagingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => MessagingBloc(repository: sl()));

  // ─── Forums Feature ───
  sl.registerLazySingleton<ForumRemoteDataSource>(
    () => ForumRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ForumRepository>(
    () => ForumRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => ForumBloc(repository: sl()));

  // ─── Notifications Feature ───
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => NotificationBloc(repository: sl()));

  // ─── Calendar Feature ───
  sl.registerLazySingleton<CalendarRemoteDataSource>(
    () => CalendarRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => CalendarBloc(repository: sl()));

  // ─── User Management Feature ───
  sl.registerLazySingleton<UserManagementRemoteDataSource>(
    () => UserManagementRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<UserManagementRepository>(
    () =>
        UserManagementRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => UserManagementBloc(repository: sl()));

  // ─── Enrollment Feature ───
  sl.registerLazySingleton<EnrollmentRemoteDataSource>(
    () => EnrollmentRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<EnrollmentRepository>(
    () => EnrollmentRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => EnrollmentBloc(repository: sl()));

  // ─── Video Meetings Feature ───
  sl.registerLazySingleton<MeetingRemoteDataSource>(
    () => MeetingRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<MeetingRepository>(
    () => MeetingRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => MeetingBloc(repository: sl()));

  // ─── Search Feature ───
  sl.registerLazySingleton<SearchRemoteDataSource>(
    () => SearchRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => SearchBloc(repository: sl(), prefs: sl()));

  // ─── Download Manager (mobile/desktop only — requires file system) ───
  if (PlatformInfo.supportsFileSystem) {
    sl.registerLazySingleton<DownloadManager>(
      () => DownloadManager(secureStorage: sl()),
    );
    await sl<DownloadManager>().init();
  }

  // ─── Offline Queue ───
  sl.registerLazySingleton<OfflineQueue>(() => OfflineQueue());
  await sl<OfflineQueue>().init();

  // ─── Connectivity ───
  sl.registerLazySingleton<ConnectivityCubit>(
    () => ConnectivityCubit(networkInfo: sl(), offlineQueue: sl()),
  );

  // ─── Theme ───
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs: sl()));

  // ─── Downloads Feature (mobile/desktop only) ───
  if (PlatformInfo.supportsFileSystem) {
    sl.registerFactory(() => DownloadsBloc(downloadManager: sl()));
  }

  // ─── AI Feature ───
  sl.registerLazySingleton(() => AiEngine(apiClient: sl()));
  sl.registerLazySingleton<AiRemoteDataSource>(
    () => AiRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(
      aiEngine: sl(),
      coursesRepository: sl(),
      courseContentRepository: sl(),
      gradeRepository: sl(),
      networkInfo: sl(),
      aiRemoteDataSource: sl<AiRemoteDataSource>(),
    ),
  );
  sl.registerFactory(() => AiInsightsBloc(repository: sl()));
  sl.registerFactory(() => AiChatBloc(repository: sl()));
  sl.registerFactory(() => AiAdminBloc(dataSource: sl()));

  // ─── Course Create ───
  sl.registerFactory(
    () => CourseCreateBloc(
      apiClient: sl(),
      coursesDataSource: sl<CoursesRemoteDataSource>(),
    ),
  );

  // ─── Social Feature ───
  sl.registerLazySingleton<SocialRemoteDataSource>(
    () => SocialRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<SocialRepository>(
    () => SocialRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => StudyGroupsBloc(repository: sl()));
  sl.registerFactory(() => StudyNotesBloc(repository: sl()));
  sl.registerFactory(() => PeerReviewBloc(repository: sl()));
  sl.registerFactory(() => CollaborativeBloc(repository: sl()));

  // ─── Gamification Feature ───
  sl.registerLazySingleton<GamificationRemoteDataSource>(
    () => GamificationRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => PointsBloc(repository: sl()));
  sl.registerFactory(() => BadgesBloc(repository: sl()));
  sl.registerFactory(() => LeaderboardBloc(repository: sl()));
  sl.registerFactory(() => ChallengesBloc(repository: sl()));

  // ─── Course Visibility Feature ───
  sl.registerFactory(() => CourseVisibilityBloc(apiClient: sl()));

  // ─── Cohort Feature ───
  sl.registerFactory(() => CohortBloc(apiClient: sl()));

  // ─── Course Management Feature ───
  sl.registerLazySingleton<CourseManagementRemoteDataSource>(
    () => CourseManagementRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerFactory(() => CourseManagementBloc(dataSource: sl()));

  // ─── Notification Admin Feature ───
  sl.registerLazySingleton<NotificationAdminRemoteDataSource>(
    () => NotificationAdminRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerFactory(() => NotificationAdminBloc(dataSource: sl()));

  // ─── Content Protection Feature ───
  sl.registerLazySingleton<ContentProtectionRemoteDataSource>(
    () => ContentProtectionRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerFactory(() => ContentProtectionBloc(dataSource: sl()));
}
