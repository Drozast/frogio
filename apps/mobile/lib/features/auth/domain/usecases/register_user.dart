import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) {
    return repository.registerWithEmailAndPassword(
      params.email,
      params.password,
      params.name,
      params.rut,
    );
  }
}

class RegisterParams {
  final String email;
  final String password;
  final String name;
  final String rut;

  RegisterParams({
    required this.email,
    required this.password,
    required this.name,
    required this.rut,
  });
}