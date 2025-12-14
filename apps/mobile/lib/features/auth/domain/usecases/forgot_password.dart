// lib/features/auth/domain/usecases/forgot_password.dart
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ForgotPassword implements UseCase<void, String> {
  final AuthRepository repository;

  ForgotPassword(this.repository);

  @override
  Future<Either<Failure, void>> call(String email) {
    return repository.forgotPassword(email);
  }
}