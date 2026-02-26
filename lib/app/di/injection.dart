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
import '../../features/student_dashboard/presentation/bloc/student_dashboard_bloc.dart';
import '../../features/admin_dashboard/presentation/bloc/admin_dashboard_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

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
}
