import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final user = await remoteDataSource.login(
        serverUrl: serverUrl,
        username: username,
        password: password,
      );

      // Cache user data
      await localDataSource.saveUser(user);
      await localDataSource.saveServerUrl(serverUrl);

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on MoodleException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await localDataSource.clearAuth();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> checkAuth() async {
    try {
      final isLoggedIn = await localDataSource.isLoggedIn();
      if (!isLoggedIn) {
        return const Left(AuthFailure(message: 'Not authenticated'));
      }

      // Try to get cached user first
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        // If online, refresh user data in background
        if (await networkInfo.isConnected) {
          try {
            final freshUser = await remoteDataSource.getSiteInfo();
            await localDataSource.saveUser(freshUser);
            return Right(freshUser);
          } catch (_) {
            // If refresh fails, still return cached data
            return Right(cachedUser);
          }
        }
        return Right(cachedUser);
      }

      // No cached user, try to fetch from server
      if (await networkInfo.isConnected) {
        final user = await remoteDataSource.getSiteInfo();
        await localDataSource.saveUser(user);
        return Right(user);
      }

      return const Left(AuthFailure(message: 'Not authenticated'));
    } on AuthException catch (e) {
      await localDataSource.clearAuth();
      return Left(AuthFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<User?> getCachedUser() async {
    return localDataSource.getCachedUser();
  }

  @override
  Future<Either<Failure, User>> refreshToken({required String password}) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Get saved server URL and username from cache
      final serverUrl = await localDataSource.getServerUrl();
      final cachedUser = await localDataSource.getCachedUser();

      if (serverUrl == null || cachedUser == null) {
        return const Left(AuthFailure(message: 'No saved credentials'));
      }

      // Re-authenticate with same server and username
      final user = await remoteDataSource.login(
        serverUrl: serverUrl,
        username: cachedUser.username,
        password: password,
      );

      // Update cached user data
      await localDataSource.saveUser(user);

      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on MoodleException catch (e) {
      return Left(ServerFailure(message: e.message, errorCode: e.errorCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<String?> getServerUrl() async {
    return localDataSource.getServerUrl();
  }
}
