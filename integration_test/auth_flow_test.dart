/// Integration tests for the MDF app — Authentication Flow.
///
/// Run with:
///   flutter test integration_test/auth_flow_test.dart
///
/// Or on a real device:
///   flutter test integration_test/ -d <deviceId>
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:mdf_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mdf_app/features/auth/presentation/pages/login_page.dart';
import 'package:mdf_app/features/auth/domain/entities/user.dart';
import 'package:mdf_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:mdf_app/core/error/failures.dart';

// ─── Mocks ───
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

class MockCheckAuthUseCase extends Mock implements CheckAuthUseCase {}

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

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    registerFallbackValue(
      const AuthLoginRequested(serverUrl: '', username: '', password: ''),
    );
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

  Widget buildApp() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: const Scaffold(body: LoginPage()),
      ),
    );
  }

  group('Auth Flow — Login Page', () {
    testWidgets('shows login form with 3 text fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Should have 3 TextFormFields: server URL, username, password
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('successful login flow', (tester) async {
      when(
        () => mockLogin(
          serverUrl: any(named: 'serverUrl'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(testUser));

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Find TextFormFields
      final fields = find.byType(TextFormField);

      // Enter server URL
      await tester.enterText(fields.at(0), 'https://moodle.example.com');
      // Enter username
      await tester.enterText(fields.at(1), 'student1');
      // Enter password
      await tester.enterText(fields.at(2), 'password123');

      // Tap login button
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pumpAndSettle();
      }

      // The bloc should have received a login event
      verify(
        () => mockLogin(
          serverUrl: 'https://moodle.example.com',
          username: 'student1',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('shows error snackbar on login failure', (tester) async {
      when(
        () => mockLogin(
          serverUrl: any(named: 'serverUrl'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Invalid credentials')),
      );

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      await tester.enterText(fields.at(0), 'https://moodle.example.com');
      await tester.enterText(fields.at(1), 'wrong');
      await tester.enterText(fields.at(2), 'wrong');

      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pump(); // Allow bloc to emit
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should show error via BlocListener
      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('validates empty fields', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // Try to submit without filling fields
      final loginButton = find.byType(ElevatedButton);
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton.first);
        await tester.pumpAndSettle();
      }

      // Login use case should NOT have been called (validation failed)
      verifyNever(
        () => mockLogin(
          serverUrl: any(named: 'serverUrl'),
          username: any(named: 'username'),
          password: any(named: 'password'),
        ),
      );
    });
  });
}
