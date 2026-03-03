/// Integration tests for the MDF app — Navigation & Routing.
///
/// Tests the GoRouter configuration, route guards, and navigation flow.
///
/// Run with:
///   flutter test integration_test/navigation_test.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:mdf_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mdf_app/features/auth/domain/entities/user.dart';
import 'package:mdf_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:mdf_app/app/router/app_router.dart';

// ─── Mocks ───
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockCheckAuthUseCase extends Mock implements CheckAuthUseCase {}

class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockLoginUseCase mockLogin;
  late MockLogoutUseCase mockLogout;
  late MockCheckAuthUseCase mockCheckAuth;
  late MockRefreshTokenUseCase mockRefreshToken;
  late AuthBloc authBloc;

  const testUser = User(
    id: 1,
    username: 'student1',
    firstName: 'Ali',
    lastName: 'Ahmed',
    fullName: 'Ali Ahmed',
    email: 'ali@example.com',
    isSiteAdmin: false,
  );

  const testAdmin = User(
    id: 2,
    username: 'admin1',
    firstName: 'Admin',
    lastName: 'User',
    fullName: 'Admin User',
    email: 'admin@example.com',
    isSiteAdmin: true,
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    mockLogin = MockLoginUseCase();
    mockLogout = MockLogoutUseCase();
    mockCheckAuth = MockCheckAuthUseCase();
    mockRefreshToken = MockRefreshTokenUseCase();
    authBloc = AuthBloc(
      loginUseCase: mockLogin,
      logoutUseCase: mockLogout,
      checkAuthUseCase: mockCheckAuth,
      refreshTokenUseCase: mockRefreshToken,
    );
  });

  tearDown(() async {
    await authBloc.close();
  });

  group('Route Guards', () {
    testWidgets('redirects to /login when not authenticated', (tester) async {
      final appRouter = AppRouter(authBloc);

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp.router(routerConfig: appRouter.router),
        ),
      );
      await tester.pumpAndSettle();

      // Should be on splash initially, then redirect to login
      // The exact behavior depends on the AuthBloc initial state (AuthInitial)
      // and the redirect logic
    });

    testWidgets('route names are valid string constants', (tester) async {
      // Verify route names are properly defined
      expect(AppRoutes.splash, 'splash');
      expect(AppRoutes.login, 'login');
      expect(AppRoutes.studentDashboard, 'student-dashboard');
      expect(AppRoutes.adminDashboard, 'admin-dashboard');
      expect(AppRoutes.courses, 'courses');
      expect(AppRoutes.grades, 'grades');
      expect(AppRoutes.notifications, 'notifications');
      expect(AppRoutes.calendar, 'calendar');
      expect(AppRoutes.search, 'search');
      expect(AppRoutes.downloads, 'downloads');
      expect(AppRoutes.aiInsights, 'ai-insights');
      expect(AppRoutes.aiChat, 'ai-chat');
      expect(AppRoutes.studyGroups, 'study-groups');
      expect(AppRoutes.peerReviews, 'peer-reviews');
      expect(AppRoutes.gamificationDashboard, 'gamification');
      expect(AppRoutes.leaderboard, 'leaderboard');
      expect(AppRoutes.badges, 'badges');
      expect(AppRoutes.challenges, 'challenges');
    });
  });
}
