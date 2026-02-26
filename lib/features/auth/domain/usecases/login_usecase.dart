import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, User>> call({
    required String serverUrl,
    required String username,
    required String password,
  }) {
    return repository.login(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
  }
}
