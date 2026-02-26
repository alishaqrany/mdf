import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Either<Failure, User>> getUserProfile(int userId);
  Future<Either<Failure, void>> updateProfile(Map<String, dynamic> userData);
}
