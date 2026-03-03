import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/mdf_error_handler.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/user_management_repository.dart';
import '../datasources/user_management_remote_datasource.dart';

class UserManagementRepositoryImpl implements UserManagementRepository {
  final UserManagementRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserManagementRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ManagedUser>>> getUsers({
    String? search,
    String? role,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final users = await remoteDataSource.getUsers(search: search, role: role);
      return Right(users);
    } catch (e) {
      return Left(
        MdfErrorHandler.handleException(e, featureName: 'إدارة المستخدمين (User Management)'),
      );
    }
  }

  @override
  Future<Either<Failure, ManagedUser>> getUserById(int userId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final user = await remoteDataSource.getUserById(userId);
      return Right(user);
    } catch (e) {
      return Left(
        MdfErrorHandler.handleException(e, featureName: 'إدارة المستخدمين (User Management)'),
      );
    }
  }

  @override
  Future<Either<Failure, ManagedUser>> createUser({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    String? department,
    String? institution,
    String? city,
    String? country,
    String? lang,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final user = await remoteDataSource.createUser(
        username: username,
        password: password,
        firstName: firstName,
        lastName: lastName,
        email: email,
        department: department,
        institution: institution,
        city: city,
        country: country,
        lang: lang,
      );
      return Right(user);
    } catch (e) {
      return Left(
        MdfErrorHandler.handleException(e, featureName: 'إدارة المستخدمين (User Management)'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? email,
    String? department,
    String? institution,
    String? city,
    String? country,
    String? lang,
    bool? suspended,
  }) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      final params = <String, dynamic>{'users[0][id]': userId};
      if (firstName != null) params['users[0][firstname]'] = firstName;
      if (lastName != null) params['users[0][lastname]'] = lastName;
      if (email != null) params['users[0][email]'] = email;
      if (department != null) params['users[0][department]'] = department;
      if (institution != null) params['users[0][institution]'] = institution;
      if (city != null) params['users[0][city]'] = city;
      if (country != null) params['users[0][country]'] = country;
      if (lang != null) params['users[0][lang]'] = lang;
      if (suspended != null) params['users[0][suspended]'] = suspended ? 1 : 0;

      await remoteDataSource.updateUser(params);
      return const Right(null);
    } catch (e) {
      return Left(
        MdfErrorHandler.handleException(e, featureName: 'إدارة المستخدمين (User Management)'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(int userId) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.deleteUser(userId);
      return const Right(null);
    } catch (e) {
      return Left(
        MdfErrorHandler.handleException(e, featureName: 'إدارة المستخدمين (User Management)'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    int userId,
    String newPassword,
  ) async {
    if (!await networkInfo.isConnected) return const Left(NetworkFailure());
    try {
      await remoteDataSource.updateUser({
        'users[0][id]': userId,
        'users[0][password]': newPassword,
      });
      return const Right(null);
    } catch (e) {
      return Left(
        MdfErrorHandler.handleException(e, featureName: 'إدارة المستخدمين (User Management)'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> toggleSuspend(int userId, bool suspend) async {
    return updateUser(userId: userId, suspended: suspend);
  }
}
