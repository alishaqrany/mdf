import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/moodle_api_client.dart';
import '../../core/network/network_info.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_usecase.dart';
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

final sl = GetIt.instance;

/// Initialize all dependencies.
Future<void> initDependencies() async {
  // ─── External ───
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Connectivity());

  // ─── Core ───
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<MoodleApiClient>(
    () => MoodleApiClient(secureStorage: sl()),
  );

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
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthUseCase: sl(),
    ),
  );

  // ─── Courses Feature ───
  sl.registerLazySingleton<CoursesRemoteDataSource>(
    () => CoursesRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<CoursesRepository>(
    () => CoursesRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
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
    () => StudentDashboardBloc(coursesRepository: sl(), authRepository: sl()),
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
}
