import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mdf_app/core/error/failures.dart';
import 'package:mdf_app/features/auth/domain/entities/user.dart';
import 'package:mdf_app/features/auth/domain/usecases/login_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/logout_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/check_auth_usecase.dart';
import 'package:mdf_app/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:mdf_app/features/auth/presentation/bloc/auth_bloc.dart';

// ─── Mocks ───
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockCheckAuthUseCase extends Mock implements CheckAuthUseCase {}

class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

void main() {
  late MockLoginUseCase mockLogin;
  late MockLogoutUseCase mockLogout;
  late MockCheckAuthUseCase mockCheckAuth;
  late MockRefreshTokenUseCase mockRefreshToken;
  late AuthBloc authBloc;

  const tUser = User(
    id: 1,
    username: 'student1',
    firstName: 'Ali',
    lastName: 'Ahmed',
    fullName: 'Ali Ahmed',
    email: 'ali@example.com',
    isSiteAdmin: false,
  );

  const tAdminUser = User(
    id: 2,
    username: 'admin1',
    firstName: 'Admin',
    lastName: 'User',
    fullName: 'Admin User',
    email: 'admin@example.com',
    isSiteAdmin: true,
  );

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

  tearDown(() => authBloc.close());

  test('initial state is AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  // ─── AuthCheckRequested ───
  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] when checkAuth succeeds',
      build: () {
        when(() => mockCheckAuth()).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user, 'user', tUser),
      ],
      verify: (_) => verify(() => mockCheckAuth()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when checkAuth fails',
      build: () {
        when(
          () => mockCheckAuth(),
        ).thenAnswer((_) async => const Left(CacheFailure()));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthUnauthenticated>()],
    );
  });

  // ─── AuthLoginRequested ───
  group('AuthLoginRequested', () {
    const tEvent = AuthLoginRequested(
      serverUrl: 'https://moodle.example.com',
      username: 'student1',
      password: 'pass123',
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful login',
      build: () {
        when(
          () => mockLogin(
            serverUrl: any(named: 'serverUrl'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having(
          (s) => s.user.username,
          'username',
          'student1',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated(admin)] for admin login',
      build: () {
        when(
          () => mockLogin(
            serverUrl: any(named: 'serverUrl'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(tAdminUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>().having((s) => s.user.isAdmin, 'isAdmin', true),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on login failure',
      build: () {
        when(
          () => mockLogin(
            serverUrl: any(named: 'serverUrl'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => const Left(AuthFailure(message: 'Invalid credentials')),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          'Invalid credentials',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] on network failure',
      build: () {
        when(
          () => mockLogin(
            serverUrl: any(named: 'serverUrl'),
            username: any(named: 'username'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Left(NetworkFailure()));
        return authBloc;
      },
      act: (bloc) => bloc.add(tEvent),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having(
          (s) => s.message,
          'message',
          'No internet connection',
        ),
      ],
    );
  });

  // ─── AuthLogoutRequested ───
  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] on logout',
      build: () {
        when(() => mockLogout()).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [isA<AuthUnauthenticated>()],
      verify: (_) => verify(() => mockLogout()).called(1),
    );
  });

  // ─── User entity ───
  group('User entity', () {
    test('displayName returns fullName', () {
      expect(tUser.displayName, 'Ali Ahmed');
    });

    test('initials returns correct initials', () {
      expect(tUser.initials, 'AA');
    });

    test('isAdmin returns false for regular user', () {
      expect(tUser.isAdmin, false);
    });

    test('isAdmin returns true for admin', () {
      expect(tAdminUser.isAdmin, true);
    });

    test('equality works based on props', () {
      const user2 = User(
        id: 1,
        username: 'student1',
        firstName: 'Ali',
        lastName: 'Ahmed',
        fullName: 'Ali Ahmed',
        email: 'ali@example.com',
        isSiteAdmin: false,
      );
      expect(tUser, equals(user2));
    });
  });
}
